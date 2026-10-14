"""Profile-mode emulator comparison of the frozen baseline and current painter."""
import json
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[1]
adb = root.parent / 'toolchains/android-sdk/platform-tools/adb.exe'
output = root.parent / 'renderer-evidence/performance'
output.mkdir(parents=True, exist_ok=True)
def run(*args):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *args]).decode()

run('shell', 'wm', 'size', '1080x2400')
run('shell', 'wm', 'density', '480')
results = []
try:
    for baseline in (True, False):
        for kind in ('pan', 'zoom'):
            run('logcat', '-c')
            config = dict(floor='bey03', room='111103.5220', dark=True,
                          view='target', legacy=False, baseline=baseline,
                          benchmark=kind, run=time.time())
            (root / 'data/renderer-fixtures/scenario.json').write_text(json.dumps(config))
            deadline = time.monotonic() + 45
            while time.monotonic() < deadline:
                time.sleep(1)
                log = run('logcat', '-d', '-s', 'flutter:I')
                matches = [line.split('RENDER_BENCH ', 1)[1] for line in log.splitlines()
                           if 'RENDER_BENCH ' in line]
                if matches:
                    result = json.loads(matches[-1])
                    if result['baseline'] == baseline and result['kind'] == kind:
                        results.append(result)
                        break
            else:
                raise RuntimeError(f'Benchmark timed out: {baseline}, {kind}\n{log}')
            name = f'{"baseline" if baseline else "current"}-{kind}'
            (output / f'{name}-meminfo.txt').write_text(
                run('shell', 'dumpsys', 'meminfo', 'com.example.campus_navigator'))
            print(json.dumps(result), flush=True)
    (output / 'frame-timings.json').write_text(json.dumps(results, indent=2))
finally:
    run('shell', 'wm', 'size', 'reset')
    run('shell', 'wm', 'density', 'reset')
