"""Android acceptance check for the universal Google Maps walking URL.

Run after installing the navigation APK on emulator-5554 and completing Chrome's
first-run setup (without an account). Temporarily disables
Maps to exercise the browser fallback, then restores it. Keeps app data intact.
"""
from pathlib import Path
import json
import re
import runpy
import time
from urllib.parse import urlparse, parse_qs

root = Path(__file__).resolve().parents[1]
out = root.parent / 'campus-navigation-evidence'
out.mkdir(exist_ok=True)
q = runpy.run_path(str(root / 'tools/smoke-campus-map.py'), run_name='helpers')
# Capture helpers use their module's globals, not this runpy result dictionary.
q['capture'].__globals__['out'] = out
run = q['run']
package = 'com.example.campus_navigator'
maps = 'com.google.android.apps.maps'
checks = []
expected = {'APB': (51.02546115, 13.72293115),
            'BAR': (51.02680695, 13.72351765)}


def record(text):
    checks.append(text)
    (out / 'checks.json').write_text(json.dumps(checks, indent=2), encoding='utf8')
    print('PASS:', text, flush=True)


def activities():
    return run('shell', 'dumpsys', 'activity', 'activities').decode(errors='replace')


def resumed(text):
    return '\n'.join(line for line in text.splitlines()
                     if 'ResumedActivity' in line or 'topResumedActivity' in line)


def return_to_campus(name):
    for _ in range(5):
        if package + '/' in resumed(activities()):
            q['exact'](name)
            q['exact']('Navigate')
            return
        run('shell', 'input', 'keyevent', '4')
        time.sleep(.7)
    raise AssertionError('Android Back did not return to the selected building')


def launch(code, name, browser=False):
    # Android keeps an activity's original base Intent after onNewIntent.
    # Start the receiver fresh so dumpsys proves this exact outbound payload.
    run('shell', 'am', 'force-stop', 'com.android.chrome' if browser else maps)
    q['choose'](code, name)
    q['exact']('Route destination: building point · entrance unverified.')
    q['capture'](f'{code.lower()}-detail')
    q['tap'](q['exact']('Navigate'))
    time.sleep(2)
    text = activities()
    if 'com.google.android.permissioncontroller/' in resumed(text):
        # Any permission here belongs to the external app, not Campus Navigator.
        q['tap'](q['wait'](lambda n: 'permission_deny' in n.get('resource-id', '')
                           and n.get('clickable') == 'true')[0])
        time.sleep(1)
        text = activities()
    (out / f'{code.lower()}-{"browser" if browser else "maps"}-activity.txt').write_text(text, encoding='utf8')
    active = resumed(text)
    assert ('com.android.chrome/' if browser else maps + '/') in active, active
    # The actual Android intent contains the unredacted outbound URL. Restrict
    # validation to the receiver's activity so an old task cannot satisfy it.
    component = 'com.android.chrome/' if browser else maps + '/'
    intents = [line for line in text.splitlines()
               if 'Intent {' in line and component in line]
    urls = [re.search(r'dat=(https://www\.google\.com/maps/dir/\?\S+)', line)
            for line in intents]
    destinations = []
    for match in urls:
        if match:
            uri = urlparse(match.group(1))
            query = parse_qs(uri.query)
            if query.get('travelmode') == ['walking'] and query.get('api') == ['1']:
                lat, lon = map(float, query['destination'][0].split(','))
                if abs(lat - expected[code][0]) < 1e-8 and abs(lon - expected[code][1]) < 1e-8:
                    assert 'origin' not in query
                    destinations.append(match.group(1))
    assert destinations, f'Expected {code} walking URL missing from receiver intents'
    q['capture'](f'{code.lower()}-{"browser" if browser else "maps"}')
    record(f'{code}: {"browser fallback" if browser else "Google Maps"}, exact WGS84 destination and walking mode verified in Android intent')
    return_to_campus(name)
    q['capture'](f'{code.lower()}-returned')
    record(f'{code}: Android Back returns with building selection intact')


disabled = maps in run('shell', 'pm', 'list', 'packages', '-d').decode()
permissions = run('shell', 'dumpsys', 'package', package).decode(errors='replace')
original_permissions = {p: f'android.permission.{p}: granted=true' in permissions
                        for p in ['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION']}
try:
    run('shell', 'wm', 'size', '1080x2400')
    run('shell', 'wm', 'density', '420')
    run('shell', 'pm', 'enable', maps)
    for permission in original_permissions:
        run('shell', 'pm', 'revoke', package, f'android.permission.{permission}')
    q['restart'](); q['campus']()
    launch('APB', 'Andreas-Pfitzmann-Bau')
    launch('BAR', 'Barkhausen-Bau')
    after = run('shell', 'dumpsys', 'package', package).decode(errors='replace')
    assert all(f'android.permission.{p}: granted=true' not in after for p in original_permissions)
    record('Both routes work without Campus Navigator location permission; no entrance coordinates are claimed')
    run('shell', 'am', 'force-stop', maps)
    run('shell', 'pm', 'disable-user', '--user', '0', maps)
    launch('APB', 'Andreas-Pfitzmann-Bau', browser=True)
    record('Maps disabled simulates unavailable app without uninstalling or deleting its data')
except Exception:
    q['capture']('failed-navigation')
    (out / 'failed-navigation-activity.txt').write_text(activities(), encoding='utf8')
    raise
finally:
    run('shell', 'pm', 'disable-user' if disabled else 'enable', maps)
    for permission, granted in original_permissions.items():
        run('shell', 'pm', 'grant' if granted else 'revoke', package, f'android.permission.{permission}')
    run('shell', 'wm', 'size', 'reset')
    run('shell', 'wm', 'density', 'reset')
    q['restart']()
    (out / 'runtime-errors.txt').write_bytes(run('logcat', '-d', '-s', 'flutter:E', 'AndroidRuntime:E'))

print('All navigation acceptance checks passed', flush=True)
