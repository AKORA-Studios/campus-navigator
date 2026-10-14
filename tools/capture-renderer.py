"""Capture deterministic real-plan views from the Android preview APK."""
import argparse
import json
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
parser.add_argument('--legacy', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
adb = root.parent / 'toolchains/android-sdk/platform-tools/adb.exe'
args.output.mkdir(parents=True, exist_ok=True)
def run(*command):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *command])

try:
    for device, size, density in [('phone', '1080x2400', '480'), ('tablet', '1920x1200', '240')]:
        run('shell', 'wm', 'size', size)
        run('shell', 'wm', 'density', density)
        time.sleep(2)
        for floor, room in [('bey00', '111100.5360'), ('bey03', '111103.5220'), ('apb00', '542100.2860')]:
            for dark in [False, True]:
                for view in ['fit', 'target']:
                    config = dict(floor=floor, room=room, dark=dark, view=view, legacy=args.legacy)
                    (root / 'data/renderer-fixtures/scenario.json').write_text(json.dumps(config))
                    expected = f'{floor} {view} {"dark" if dark else "light"} {"AKORA" if args.legacy else "renderer"}'
                    for attempt in range(15):
                        time.sleep(1)
                        run('shell', 'uiautomator', 'dump', '/sdcard/renderer.xml')
                        xml = run('shell', 'cat', '/sdcard/renderer.xml').decode()
                        if expected in xml:
                            break
                    else:
                        raise RuntimeError(f'Preview not ready: {expected}')
                    time.sleep(.25)
                    name = f'{floor}-{device}-{"dark" if dark else "light"}-{view}.png'
                    (args.output / name).write_bytes(run('exec-out', 'screencap', '-p'))
                    print(name, flush=True)
finally:
    run('shell', 'wm', 'size', 'reset')
    run('shell', 'wm', 'density', 'reset')
