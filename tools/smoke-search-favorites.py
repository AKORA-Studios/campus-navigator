"""Exercise installed app with real TU API and durable Android storage.

Only adds/removes the explicitly named demonstration favorites. Never clears
app data, the user's history or unrelated favorites. Screenshots stay outside Git.
"""
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
adb = root.parent / 'toolchains/android-sdk/platform-tools/adb.exe'
output = root.parent / 'search-favorites-evidence'
output.mkdir(exist_ok=True)
package = 'com.example.campus_navigator'


def run(*args):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *args])


def nodes():
    for _ in range(5):
        dump = run('shell', 'uiautomator', 'dump', '/sdcard/search-favorites.xml')
        if b'dumped to:' in dump:
            return list(ET.fromstring(run('shell', 'cat', '/sdcard/search-favorites.xml')).iter('node'))
        time.sleep(.5)
    raise RuntimeError('No fresh Android UI hierarchy')


def label(node):
    return (node.get('content-desc') or node.get('text') or '').strip()


def tap(node):
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
    run('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))


def wait_for(predicate, attempts=15):
    for _ in range(attempts):
        current = nodes()
        found = [n for n in current if predicate(n)]
        if found:
            return found
        time.sleep(.3)
    raise RuntimeError('Expected UI state not reached')


def row(name):
    return wait_for(lambda n: label(n).splitlines()[:1] == [name]
                    and n.get('clickable') == 'true'
                    and n.get('class') != 'android.widget.EditText')[0]


def capture(name):
    time.sleep(.3)  # Capture settled pixels after Android accessibility refresh.
    (output / f'{name}.png').write_bytes(run('exec-out', 'screencap', '-p'))


def mode(dark):
    run('shell', 'cmd', 'uimode', 'night', 'yes' if dark else 'no')
    nodes()


def restart():
    run('shell', 'am', 'force-stop', package)
    run('shell', 'am', 'start', '-n', f'{package}/.MainActivity')
    wait_for(lambda n: label(n) == 'Favorites')


def search(query, title):
    restart()  # Also verifies durable favorites on every new query.
    edit = next(n for n in nodes() if n.get('class') == 'android.widget.EditText')
    tap(edit)
    nodes()
    for char in query.lower():
        if char == ' ':
            run('shell', 'input', 'keyevent', '62')
        else:
            run('shell', 'input', 'text', char)
        time.sleep(.08)
    assert any(n.get('class') == 'android.widget.EditText' and n.get('text') == query.lower()
               for n in nodes()), 'Input was not delivered'
    run('shell', 'input', 'keyevent', '66')
    row(title)


def favorite(name, wanted=True, verify_label=True):
    buttons = wait_for(lambda n: label(n) in
                       [f'Save favorite: {name}', f'Remove favorite: {name}'])
    current = label(buttons[0]).startswith('Remove favorite:')
    if current != wanted:
        tap(buttons[0])
    expected = f'{"Remove" if wanted else "Save"} favorite: {name}'
    if verify_label:
        for _ in range(15):
            current = nodes()
            if any(label(n) == expected and n.get('enabled') == 'true' for n in current):
                break
            # Removing a building from the home list removes its entire row.
            if not wanted and not any(label(n) == f'Remove favorite: {name}' for n in current):
                break
            time.sleep(.3)
        else:
            raise RuntimeError(f'Favorite change not reflected: {name}')


def open_map(name):
    tap(row(name))
    wait_for(lambda n: label(n).startswith('Filter ('))
    time.sleep(3)


def back_home():
    run('shell', 'input', 'keyevent', '4')
    wait_for(lambda n: n.get('class') == 'android.widget.EditText')


try:
    run('logcat', '-c')
    mode(False)
    restart()
    if not (output / 'after-empty-light.png').exists():
        capture('after-empty-light')
    mode(True)
    if not (output / 'after-empty-dark.png').exists():
        capture('after-empty-dark')
    mode(False)

    search('BEY 318', 'BEY 318')
    capture('after-search-light')
    mode(True)
    capture('after-search-dark')
    mode(False)
    favorite('BEY 318')
    favorite('Beyer-Bau')
    open_map('BEY 318')
    capture('bey318-map-light')
    # Android 14's accessibility dump can retain the app-bar label after a
    # repaint. Check the visible icon and durable state after a fresh launch.
    favorite('BEY 318', False, verify_label=False)
    capture('map-favorite-removed')
    back_home()
    restart()
    assert len([n for n in nodes() if label(n).splitlines()[:1] == ['BEY 318']]) == 1
    capture('room-removed-after-restart')
    favorite('BEY 318', True)
    restart()
    assert len([n for n in nodes() if label(n).splitlines()[:1] == ['BEY 318']]) >= 2
    row('Beyer-Bau')
    capture('after-restart-phone-light')
    print('BEY room/building favorites, map action and durable restart passed', flush=True)

    search('APB E069', 'APB E069')
    favorite('APB E069')
    open_map('APB E069')
    capture('apbE069-map-light')
    mode(True)
    capture('apbE069-map-dark')
    mode(False)
    back_home()
    restart()
    row('BEY 318'); row('APB E069'); row('Beyer-Bau')
    capture('after-home-phone-light')
    mode(True)
    capture('after-home-phone-dark')
    mode(False)
    print('APB room, history and light/dark home passed', flush=True)

    open_map('Beyer-Bau')
    wait_for(lambda n: label(n) == '00')
    capture('building-favorite-floor00')
    back_home()
    restart()
    # A building removed from Favorites disappears; there is no opposite star
    # left on this screen. Verify absence after restart instead.
    favorite('Beyer-Bau', False)
    restart()
    assert not any(label(n).splitlines()[:1] == ['Beyer-Bau'] for n in nodes())
    capture('building-removed-after-restart')
    search('BEY 318', 'BEY 318')
    favorite('Beyer-Bau')
    restart()
    print('Building floor resolution and durable removal passed', flush=True)

    run('shell', 'wm', 'size', '1920x1200')
    run('shell', 'wm', 'density', '240')
    restart()
    capture('after-home-tablet-light')
    mode(True)
    capture('after-home-tablet-dark')
    mode(False)
    open_map('BEY 318')
    capture('bey318-tablet-map')
    run('shell', 'input', 'swipe', '900', '600', '800', '660', '500')
    capture('bey318-tablet-panned')
    print('Landscape tablet home, map and panning passed', flush=True)
except Exception:
    capture('failed-scenario')
    raise
finally:
    run('shell', 'wm', 'size', 'reset')
    run('shell', 'wm', 'density', 'reset')
    mode(False)
    restart()

errors = run('logcat', '-d', '-s', 'flutter:E', 'AndroidRuntime:E').decode()
(output / 'runtime-errors.txt').write_text(errors, encoding='utf8')
if errors.strip():
    raise RuntimeError(errors)
capture('final-home-phone')
print('All live search/favorite scenarios passed; app left on home', flush=True)
