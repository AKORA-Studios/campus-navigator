"""Build comparison boards and a local gallery from real emulator captures."""
from pathlib import Path
import hashlib
from html import escape
import json
import subprocess
from PIL import Image, ImageDraw

repo = Path(__file__).resolve().parents[1]
output = repo.parent / 'search-favorites-evidence'
apk = 'campus-navigator-1.1.0-search-favorites.apk'


def board(filename, entries):
    result = Image.new('RGB', (360 * len(entries), 675), 'white')
    draw = ImageDraw.Draw(result)
    for index, (source, title) in enumerate(entries):
        result.paste(Image.open(output / source).resize((360, 640)), (360 * index, 35))
        draw.text((360 * index + 10, 12), title, fill='black')
    result.save(output / filename)


for mode in ['light', 'dark']:
    board(f'comparison-search-{mode}.png', [
        (f'before-search-{mode}.png', 'BISHER / 49a4dfa'),
        (f'after-search-{mode}.png', 'NEU / SUCHE UND FAVORITEN')])
    board(f'comparison-home-{mode}.png', [
        (f'before-{mode}.png', 'BISHER / 49a4dfa'),
        (f'after-empty-{mode}.png', 'NEU / LEER'),
        (f'after-home-phone-{mode}.png', 'NEU / FAVORITEN UND VERLAUF')])

entries = [
    ('comparison-home-light.png', 'Startansicht: vorher, leer und mit gespeicherten Zielen'),
    ('comparison-home-dark.png', 'Startansicht im Dunkelmodus'),
    ('comparison-search-light.png', 'Identische Suche BEY 318: vorher und nachher'),
    ('comparison-search-dark.png', 'Identische Suche im Dunkelmodus'),
    ('after-home-tablet-light.png', 'Tablet-Querformat, Hellmodus'),
    ('after-home-tablet-dark.png', 'Tablet-Querformat, Dunkelmodus'),
    ('bey318-tablet-map.png', 'Raumfavorit BEY 318 auf dem Tablet'),
    ('building-favorite-floor00.png', 'Gebäudefavorit öffnet eine gültige Etage'),
    ('room-removed-after-restart.png', 'Raumfavorit entfernt, Verlauf nach Neustart erhalten'),
    ('building-removed-after-restart.png', 'Gebäudefavorit nach Neustart entfernt'),
    ('final-home-phone.png', 'Endgültige Release-APK auf dem Smartphone-Viewport'),
]
figures = ''.join(f'<figure><figcaption>{escape(title)}</figcaption>'
                  f'<a href="{name}"><img src="{name}" loading="lazy"></a></figure>'
                  for name, title in entries)
(output / 'index.html').write_text('''<!doctype html><html lang="de"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Campus Navigator – Suche und Favoriten</title>
<style>body{font:16px system-ui,sans-serif;max-width:1250px;margin:24px auto;padding:0 16px;background:#f6f7f8;color:#20292d}h1{font-size:24px}figure{margin:28px 0}figcaption{margin-bottom:10px}img{max-width:100%;max-height:850px;border:1px solid #ccd1d3}a{color:#006c68}</style>
<h1>Campus Navigator 1.1.0 – Suche und Favoriten</h1>
<p>Reale Emulatoraufnahmen: gleiche Smartphone-Auflösung vor und nach der Änderung.
Die Übersichtsbilder sind verkleinert; alle Originalaufnahmen bleiben erhalten.
Tablet-Querformat: 1920 × 1200. Der Emulator verwendet Englisch; die App unterstützt auch Deutsch.</p>
<p>80 Tests bestanden, darunter 24 unveränderte Originalplan-Goldens.
Favoriten und Verlauf nach vollständigem Prozessneustart geprüft.</p>
''' + f'<p><a href="{apk}">Installierbare Universal-Test-APK herunterladen</a></p>'
    + figures + '</html>', encoding='utf8')

manifest = {
    'baselineCommit': '49a4dfa',
    'featureCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(),
    'masterCommit': subprocess.check_output(['git', 'rev-parse', 'master'], cwd=repo, text=True).strip(),
    'apk': apk,
    'apkSHA256': hashlib.sha256((output / apk).read_bytes()).hexdigest(),
    'testsPassed': 80,
    'testsSkipped': 1,
    'screenshots': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in sorted(output.glob('*.png'))},
}
(output / 'evidence.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
print('Comparison boards, gallery and evidence hashes saved')
