"""Create reviewable before/after boards without changing screenshot pixels."""
from html import escape
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / 'renderer-evidence'
output = root / 'comparisons'
output.mkdir(exist_ok=True)
links = []
for before in sorted((root / 'baseline').glob('*.png')):
    after = root / 'final' / before.name
    if not after.exists():
        raise FileNotFoundError(after)
    a, b = Image.open(before).convert('RGB'), Image.open(after).convert('RGB')
    if a.size != b.size:
        raise ValueError(f'Viewport mismatch: {before.name}')
    # Keep complete screenshots: camera and architecture are untouched.
    board = Image.new('RGB', (a.width * 2, a.height + 40), 'white')
    board.paste(a, (0, 40))
    board.paste(b, (a.width, 40))
    draw = ImageDraw.Draw(board)
    draw.text((10, 10), f'BEFORE 37d4d68 / {before.stem}', fill='black')
    draw.text((a.width + 10, 10), f'AFTER / {before.stem}', fill='black')
    board.save(output / before.name)
    links.append(f'<p>{escape(before.stem)}</p><a href="comparisons/{before.name}"><img src="comparisons/{before.name}" loading="lazy"></a>')

for floor, crop in [('bey00', (200, 950, 1080, 1580)),
                    ('bey03', (200, 780, 850, 1680)),
                    ('apb00', (0, 740, 960, 1560))]:
    board = Image.new('RGB', ((crop[2] - crop[0]) * 4,
                              crop[3] - crop[1] + 40), 'white')
    width = crop[2] - crop[0]
    draw = ImageDraw.Draw(board)
    for index, (version, mode) in enumerate([
            ('baseline', 'light'), ('final', 'light'),
            ('baseline', 'dark'), ('final', 'dark')]):
        img = Image.open(root / version / f'{floor}-phone-{mode}-target.png')
        board.paste(img.crop(crop), (index * width, 40))
        draw.text((index * width + 10, 10), f'{version.upper()} / {mode}', fill='black')
    board.save(output / f'{floor}-detail.png')

# The website's BEY target is approximately the same logical map scale.
# Normalize emulator pixel density, align the target, retain source colors.
board = Image.new('RGB', (195 * 4, 250), 'white')
draw = ImageDraw.Draw(board)
references = [
    ('TU website', Image.open(root / 'website-bey03-zoom.png').crop((485, 285, 680, 495))),
    ('Before', Image.open(root / 'baseline/bey03-phone-light-target.png')
        .crop((225, 855, 810, 1485)).resize((195, 210), Image.Resampling.LANCZOS)),
    ('After light', Image.open(root / 'final/bey03-phone-light-target.png')
        .crop((225, 855, 810, 1485)).resize((195, 210), Image.Resampling.LANCZOS)),
    ('After dark', Image.open(root / 'final/bey03-phone-dark-target.png')
        .crop((225, 855, 810, 1485)).resize((195, 210), Image.Resampling.LANCZOS)),
]
for index, (title, img) in enumerate(references):
    board.paste(img, (index * 195, 40))
    draw.text((index * 195 + 8, 10), title, fill='black')
board.save(output / 'bey03-reference-detail.png')

(root / 'index.html').write_text('''<!doctype html><html lang="de"><meta charset="utf-8">
<title>Renderer-Vergleich</title><style>body{font:16px sans-serif;margin:24px;background:#eee}img{max-width:100%;height:auto}p{margin-top:40px}a{color:#114879}</style>
<h1>Campus Navigator: visuelle Prüfung</h1><p>Unveränderte Ausgangsversion 37d4d68 und finale Darstellung. Gleiche Originaldaten, Kamera, Zoom und Viewport. Smartphone: 360×800 dp / Dichte 3; Tablet: 1280×800 dp / Dichte 1,5. Vollständige Emulatorbilder anklicken. Website-Referenzen und AKORA-Serie liegen separat im selben Ordner.</p>
''' + ''.join(links) + '</html>', encoding='utf-8')
print(f'Created {len(links)} full comparisons and three detail boards: {output}')
