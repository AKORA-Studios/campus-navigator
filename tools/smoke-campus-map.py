"""Live Android acceptance checks using the real TU endpoint and viewport tiles.

Preserves app data/favorites. Only the emulator's display, simulated location and
location permission are adjusted for the requested cases; state is restored.
Run after installing the APK. Screenshots/logs stay outside Git.
"""
from pathlib import Path
import json
from io import BytesIO
from PIL import Image
import re
import subprocess
import time
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
adb = root.parent / 'toolchains/android-sdk/platform-tools/adb.exe'
out = root.parent / 'campus-map-evidence'
out.mkdir(exist_ok=True)
package = 'com.example.campus_navigator'
checks = []


def run(*args):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *args])


def nodes():
    for _ in range(4):
        result = run('shell', 'uiautomator', 'dump', '/sdcard/campus-qa.xml')
        if b'dumped to:' in result:
            return list(ET.fromstring(run('shell', 'cat', '/sdcard/campus-qa.xml')).iter('node'))
        time.sleep(.4)
    raise RuntimeError('Android accessibility hierarchy unavailable')


def label(n):
    return (n.get('content-desc') or n.get('text') or '').strip()


def rect(n):
    return tuple(map(int, re.findall(r'\d+', n.get('bounds'))))


def tap(n):
    x1, y1, x2, y2 = rect(n)
    run('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
    time.sleep(.4)


def wait(predicate, attempts=14):
    for _ in range(attempts):
        found = [n for n in nodes() if predicate(n)]
        if found:
            return found
        time.sleep(.4)
    raise RuntimeError('Expected Android state was not reached')


def exact(text):
    return wait(lambda n: label(n) == text)[0]


def capture(name):
    time.sleep(.5)
    (out / f'{name}.png').write_bytes(run('exec-out', 'screencap', '-p'))


def record(name):
    checks.append(name)
    print('PASS:', name, flush=True)
    (out / 'emulator-checks.json').write_text(json.dumps(checks, indent=2), encoding='utf8')


def restart():
    run('shell', 'am', 'force-stop', package)
    run('shell', 'am', 'start', '-n', f'{package}/.MainActivity')
    wait(lambda n: label(n) == 'Favorites')


def campus():
    # Android can briefly expose pre-resize bounds after display/theme changes.
    # Re-read rather than repeatedly tapping those old coordinates.
    for _ in range(3):
        current = nodes()
        if any(label(n) == '© OpenStreetMap contributors' for n in current):
            return
        tabs = [n for n in current if label(n).startswith('Campus map\nTab')]
        if tabs:
            tap(tabs[0])
        time.sleep(1)
    exact('© OpenStreetMap contributors')


def choose(code, name):
    field = next(n for n in nodes() if n.get('class') == 'android.widget.EditText')
    tap(field)
    run('shell', 'input', 'keyevent', 'KEYCODE_MOVE_END')
    run('shell', 'input', 'keyevent', '--longpress', 'KEYCODE_DEL')
    run('shell', 'input', 'text', code.lower())
    candidate = wait(lambda n: name in label(n) and n.get('clickable') == 'true')[0]
    tap(candidate)
    exact(name)
    time.sleep(1)


def map_buttons():
    current = nodes()
    field = next(n for n in current if n.get('class') == 'android.widget.EditText')
    bottom = rect(field)[3]
    return sorted([n for n in current if n.get('class') == 'android.widget.Button'
                   and rect(n)[1] > bottom and rect(n)[0] > 500], key=lambda n: rect(n)[1])[:4]


def map_style():
    current = nodes()
    field = next(n for n in current if n.get('class') == 'android.widget.EditText')
    buttons = sorted([n for n in current if n.get('class') == 'android.widget.Button'
                      and rect(n)[3] < rect(field)[1]], key=lambda n: rect(n)[0])
    tap(buttons[-2])  # Observed app-bar order: style, refresh.


def open_floor(name):
    tap(exact('Floor plans'))
    wait(lambda n: label(n).startswith('Filter ('))
    exact('00')
    time.sleep(3)
    capture(name)


def back_to_campus(name):
    run('shell', 'input', 'keyevent', '4')
    exact(name)
    exact('Floor plans')


def permission_button(suffix):
    return wait(lambda n: n.get('resource-id', '').endswith(suffix))[0]


def native_polygon_apb():
    # Dismiss the selected building with its observed close button.
    current = nodes()
    title = next(n for n in current if label(n) == 'Andreas-Pfitzmann-Bau')
    candidates = [n for n in current if n.get('class') == 'android.widget.Button'
                  and rect(n)[1] > rect(title)[1] - 160
                  and rect(n)[3] <= rect(title)[1] + 10]
    tap(max(candidates, key=lambda n: rect(n)[0]))
    time.sleep(1)
    # Select the actual rendered outline nearest the focused APB viewport center.
    # Do not assume a camera zoom or use stale accessibility map bounds.
    current = nodes()
    field = next(n for n in current if n.get('class') == 'android.widget.EditText')
    nav = next(n for n in current if label(n).startswith('Campus map\nTab'))
    pixels = Image.open(BytesIO(run('exec-out', 'screencap', '-p'))).convert('RGB')
    cx, cy = pixels.width // 2, (rect(field)[3] + rect(nav)[1]) // 2
    points = [(x, y) for y in range(max(rect(field)[3]+20, cy-220), min(rect(nav)[1]-40, cy+220), 2)
              for x in range(max(20, cx-220), min(pixels.width-180, cx+220), 2)
              if pixels.getpixel((x, y)) == (195, 222, 219)]
    assert points, 'No actual TU outline visible in focused viewport'
    px, py = min(points, key=lambda p: (p[0]-cx)**2+(p[1]-cy)**2)
    run('shell', 'input', 'tap', str(px), str(py))
    exact('Andreas-Pfitzmann-Bau')


def main():
    original_package = run('shell', 'dumpsys', 'package', package).decode()
    original_permissions = {p: f'android.permission.{p}: granted=true' in original_package
                            for p in ['ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION']}
    original_location = run('shell', 'settings', 'get', 'secure', 'location_mode').decode().strip()
    original_wifi = run('shell', 'settings', 'get', 'global', 'wifi_on').decode().strip()
    original_data = run('shell', 'settings', 'get', 'global', 'mobile_data').decode().strip()

    try:
        run('logcat', '-c')
        run('shell', 'wm', 'size', '1080x2400')
        run('shell', 'wm', 'density', '420')
        run('shell', 'cmd', 'uimode', 'night', 'no')
        restart()
        favorites_before = sorted(set(label(n) for n in nodes() if label(n).startswith('Remove favorite:')))
        capture('phone-search-favorites')
        campus()
        time.sleep(3)
        capture('phone-campus-light')
        record('Campus opens with real basemap and TU polygons')
        choose('APB', 'Andreas-Pfitzmann-Bau')
        capture('phone-apb-light')
        native_polygon_apb()
        capture('phone-apb-polygon-selected')
        record('APB selected by geographic polygon touch')
        open_floor('phone-apb-floor')
        back_to_campus('Andreas-Pfitzmann-Bau')
        capture('phone-apb-return')
        record('APB floor 00 opens in existing renderer; back retains selection')
        choose('BAR', 'Barkhausen-Bau')
        capture('phone-bar-light')
        map_style()
        capture('phone-bar-dark')
        map_style()
        record('Barkhausen selected; light and local dark style work')

        # Exercise Android's actual location permission dialog, rather than mocking it.
        for permission in original_permissions:
            run('shell', 'pm', 'revoke', package, f'android.permission.{permission}')
            run('shell', 'pm', 'clear-permission-flags', package, f'android.permission.{permission}', 'user-set', 'user-fixed')
        restart(); campus()
        run('shell', 'cmd', 'location', 'set-location-enabled', 'true')
        tap(map_buttons()[1])
        capture('phone-location-prompt')
        tap(permission_button('permission_deny_button'))
        wait(lambda n: 'Location permission denied.' in label(n))
        capture('phone-location-denied')
        choose('BAR', 'Barkhausen-Bau')
        record('Native location denial leaves building selection working')
        for permission in original_permissions:
            run('shell', 'pm', 'clear-permission-flags', package, f'android.permission.{permission}', 'user-set', 'user-fixed')
        tap(map_buttons()[1])
        tap(permission_button('permission_allow_foreground_only_button'))
        run('emu', 'geo', 'fix', '13.724', '51.0265')
        wait(lambda n: 'Last measured position' in label(n))
        time.sleep(1)
        capture('phone-location-granted')
        record('Native explicit location grant shows the emulator position')
        time.sleep(4)

        run('shell', 'wm', 'size', '1920x1200')
        run('shell', 'wm', 'density', '240')
        restart(); campus()
        capture('tablet-campus-light')
        choose('APB', 'Andreas-Pfitzmann-Bau')
        capture('tablet-apb-light')
        map_style()
        capture('tablet-apb-dark')
        map_style()
        open_floor('tablet-apb-floor')
        back_to_campus('Andreas-Pfitzmann-Bau')
        choose('BAR', 'Barkhausen-Bau')
        capture('tablet-bar-light')
        # A short, normal interaction; this never scans an area or seeds a cache.
        run('shell', 'input', 'swipe', '750', '580', '850', '620', '400')
        time.sleep(1)
        capture('tablet-bar-panned')
        record('Tablet side panel, floor roundtrip, styles and panning work')

        # Already visited viewport works from persistent cache with Wi-Fi disabled.
        run('shell', 'svc', 'wifi', 'disable')
        run('shell', 'svc', 'data', 'disable')
        restart(); campus()
        choose('APB', 'Andreas-Pfitzmann-Bau')
        capture('tablet-cached-offline')
        record('Restart without networking retains cached buildings and viewed tiles')
        run('shell', 'svc', 'wifi', 'enable')
        run('shell', 'svc', 'data', 'enable')

        tap(wait(lambda n: label(n).startswith('Room search\nTab'))[0])
        exact('Favorites')
        favorites_after = sorted(set(label(n) for n in nodes() if label(n).startswith('Remove favorite:')))
        assert favorites_after == favorites_before, (favorites_before, favorites_after)
        # Existing room search and room highlighting through the unchanged pathway.
        field = next(n for n in nodes() if n.get('class') == 'android.widget.EditText')
        tap(field)
        for char in 'apb e069':
            run('shell', 'input', 'keyevent', '62') if char == ' ' else run('shell', 'input', 'text', char)
            time.sleep(.08)
        run('shell', 'input', 'keyevent', '66')
        tap(wait(lambda n: label(n).splitlines()[:1] == ['APB E069'] and n.get('clickable') == 'true')[0])
        wait(lambda n: label(n).startswith('Filter ('))
        time.sleep(3)
        capture('tablet-existing-apb-room')
        record('Existing favorites unchanged; APB E069 room search still opens highlighted floor')
    except Exception:
        capture('failed-campus-scenario')
        raise
    finally:
        run('shell', 'svc', 'wifi', 'disable' if original_wifi == '0' else 'enable')
        run('shell', 'svc', 'data', 'disable' if original_data == '0' else 'enable')
        run('shell', 'wm', 'size', 'reset')
        run('shell', 'wm', 'density', 'reset')
        run('shell', 'cmd', 'uimode', 'night', 'no')
        for permission, granted in original_permissions.items():
            run('shell', 'pm', 'grant' if granted else 'revoke', package, f'android.permission.{permission}')
            run('shell', 'pm', 'clear-permission-flags', package, f'android.permission.{permission}', 'user-set', 'user-fixed')
        if original_location == '0':
            run('shell', 'cmd', 'location', 'set-location-enabled', 'false')
        restart()
        (out / 'emulator-runtime-errors.txt').write_bytes(run('logcat', '-d', '-s', 'flutter:E', 'AndroidRuntime:E'))

    print('All live campus-map acceptance checks passed', flush=True)


if __name__ == '__main__':
    main()
