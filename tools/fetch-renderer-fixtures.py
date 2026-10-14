"""Freeze only the three explicitly selected floors for local renderer QA.

The output contains original TU data and belongs in the ignored data directory.
No campus crawl. Four workers, retries, hashes, and unmodified PNG bytes.
"""
import concurrent.futures
import hashlib
import json
import math
from pathlib import Path
import re
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1] / 'data' / 'renderer-fixtures'
BASE = 'https://navigator.tu-dresden.de'

def fetch(item):
    name, url = item
    path = ROOT / name
    if not path.exists():
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=30) as response:
                    data = response.read()
                if name.endswith('.png') and data and not data.startswith(b'\x89PNG'):
                    raise ValueError(f'Not a PNG: {url}')
                path.write_bytes(data)
                break
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(1 + attempt)
    return {'file': name, 'url': url, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

jobs = {}
metadata = []
ROOT.mkdir(parents=True, exist_ok=True)
for floor, room in [('bey00', '111100.5360'), ('bey03', '111103.5220'), ('apb00', '542100.2860')]:
    path = ROOT / f'{floor}.html'
    if not path.exists():
        url = f'{BASE}/etplan/{floor[:3]}/{floor[3:]}/raum/{room}'
        with urllib.request.urlopen(url, timeout=30) as response:
            body = response.read().decode(response.headers.get_content_charset() or 'utf-8')
        path.write_text(body, encoding='utf-8')
for floor in ('bey00', 'bey03', 'apb00'):
    body = (ROOT / f'{floor}.html').read_text(encoding='utf-8', errors='replace')
    prefix = re.search(r'var png_file_name = "([^"]+)"', body)[1]
    width = int(re.search(r'data_canv_width = (\d+)', body)[1])
    height = int(re.search(r'data_canv_height = (\d+)', body)[1])
    click = json.loads(re.search(r'this\.raumclick = (\{[^;]+)', body)[1])
    wanted = [v[:2] for v in click.values() if v[1] in ('E25', 'E26', '318', '319A', 'E069')]
    metadata.append({'floor': floor, 'prefix': prefix, 'width': width, 'height': height, 'rooms': wanted})
    for step in (1, 2, 4, 8):
        for x in range(math.ceil(width * step / 480)):
            for y in range(math.ceil(height * step / 480)):
                jobs[f'{prefix}_{step}_{x}_{y}.png'] = f'{BASE}/images/etplan_cache/{prefix}_{step}/{x}_{y}.png/nobase64'
    for symbol in set(re.findall(r'"?symbolPNG"?\s*:\s*"([^"]+)"', body)):
        jobs[symbol] = f'{BASE}/images/symbols/{symbol}'
print(json.dumps(metadata, indent=2), flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    manifest = list(pool.map(fetch, jobs.items()))
(ROOT / 'manifest.json').write_text(json.dumps({'floors': metadata, 'files': manifest}, indent=2))
print(f'Frozen {len(manifest)} PNGs', flush=True)
