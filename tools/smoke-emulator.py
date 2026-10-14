"""Exercise the regular app's real search/API, not the fixture preview."""
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
adb = root.parent / 'toolchains/android-sdk/platform-tools/adb.exe'
output = root.parent / 'renderer-evidence/main'
output.mkdir(parents=True, exist_ok=True)
def run(*args):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *args])
def nodes():
    for attempt in range(5):
        dumped = run('shell', 'uiautomator', 'dump', '/sdcard/smoke.xml')
        if b'dumped to:' in dumped:
            return list(ET.fromstring(run('shell', 'cat', '/sdcard/smoke.xml')).iter('node'))
        time.sleep(1)
    raise RuntimeError('Emulator did not provide a fresh UI hierarchy')
def text(node):
    return (node.get('content-desc') or node.get('text') or '').strip()
def tap(node):
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
    run('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
def screenshot(name):
    (output / name).write_bytes(run('exec-out', 'screencap', '-p'))

for floor, query in [('bey00', 'BEY E25'), ('apb00', 'APB E069'), ('bey03', 'BEY 318')]:
    run('shell', 'cmd', 'uimode', 'night', 'no')
    run('shell', 'am', 'force-stop', 'com.example.campus_navigator')
    run('shell', 'am', 'start', '-n', 'com.example.campus_navigator/.MainActivity')
    time.sleep(3)
    edit = next(n for n in nodes() if n.get('class') == 'android.widget.EditText')
    tap(edit)
    nodes()  # Observe focus/keyboard after the tap before injecting text.
    # Slow separate key injection avoids dropped modifier events from adb's
    # rapid uppercase input on this emulator. The API accepts lowercase.
    for char in query.lower():
        if char == ' ':
            run('shell', 'input', 'keyevent', '62')
        else:
            run('shell', 'input', 'text', char)
        time.sleep(.08)
    assert any(n.get('class') == 'android.widget.EditText' and n.get('text') == query.lower()
               for n in nodes()), f'Input was not delivered: {query}'
    run('shell', 'input', 'keyevent', '66')
    for attempt in range(15):
        time.sleep(1)
        results = [n for n in nodes() if text(n).splitlines()[:1] == [query]
                   and n.get('class') != 'android.widget.EditText']
        if results:
            tap(results[-1])
            break
    else:
        raise RuntimeError(f'No real search result: {query}')
    time.sleep(5)
    assert any(text(n).startswith('Filter (') for n in nodes()), query
    screenshot(f'{floor}-light-target.png')
    run('shell', 'cmd', 'uimode', 'night', 'yes')
    time.sleep(2)
    screenshot(f'{floor}-dark-target.png')
    # Observed native 1080x1920 fit button, same regular-app viewport each time.
    run('shell', 'input', 'tap', '998', '1605')
    time.sleep(3)
    screenshot(f'{floor}-dark-fit.png')
    run('shell', 'cmd', 'uimode', 'night', 'no')
    time.sleep(2)
    screenshot(f'{floor}-light-fit.png')
    print(f'Real search + light/dark + target/fit: {query}', flush=True)

# Exercise panning in the actual app and leave it open for the user.
run('shell', 'input', 'swipe', '500', '900', '430', '940', '500')
errors = run('logcat', '-d', '-s', 'flutter:E', 'AndroidRuntime:E').decode()
(output / 'runtime-errors.txt').write_text(errors)
if errors.strip():
    raise RuntimeError(errors)
