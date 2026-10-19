#!/usr/bin/env python3
"""Cut the user's three original power-up illustrations into transparent PNGs.

Usage: python3 tool/tile_quest/extract_powerups.py --preview /tmp/powerups.png
Requires Pillow and numpy.  The original sheet is never rewritten or flattened.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

project_root = Path(__file__).resolve().parents[2]
source_path = project_root / 'assets/img/tile_quest/2.png'
output_dir = project_root / 'assets/img/tile_quest/powerups'
source_size = (2172, 724)
powerup_names = ('undo', 'shuffle', 'remove')
canvas_size = 256
subject_size = 224
solid_alpha_threshold = 127
support_diameter = 5


def extract_source(source: Image.Image, index: int) -> tuple[Image.Image, tuple[int, int, int, int]]:
    """Select one connected illustration, preserving its RGB, alpha and holes.

    The shuffle artwork extends across the nominal third-column boundary, so
    selection operates on the complete sheet instead of cutting equal cells.
    The closest opaque pixel to each third's centre seeds a connected body.
    Its two-pixel support band retains fractional edge alpha while removing
    detached specks.  Original transparent openings remain transparent.
    """
    alpha = np.asarray(source.getchannel('A'), dtype=np.uint8)
    solid_y, solid_x = np.nonzero(alpha > solid_alpha_threshold)
    if not len(solid_x):
        raise ValueError('The source contains no opaque illustration.')
    center_x = (index + .5) * source.width / len(powerup_names)
    center_y = source.height / 2
    distances = (solid_x - center_x) ** 2 + (solid_y - center_y) ** 2
    seed_index = int(distances.argmin())
    seed = (int(solid_x[seed_index]), int(solid_y[seed_index]))
    connected = Image.fromarray(np.where(alpha > solid_alpha_threshold, 255, 0).astype(np.uint8)).copy()
    ImageDraw.floodfill(connected, seed, 128, thresh=0)
    body = Image.fromarray(np.where(np.asarray(connected) == 128, 255, 0).astype(np.uint8))
    support = np.asarray(body.filter(ImageFilter.MaxFilter(support_diameter))) > 0
    image = source.copy()
    image.putalpha(Image.fromarray(np.where(support, alpha, 0).astype(np.uint8)))
    bounds = image.getbbox()
    if bounds is None:
        raise ValueError(f'No connected illustration found for {powerup_names[index]}.')
    return image.crop(bounds), bounds


def fit_icon(image: Image.Image) -> Image.Image:
    """Fit the proportional silhouette to a shared 224-pixel visual envelope."""
    scale = subject_size / max(image.size)
    fitted = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (canvas_size, canvas_size))
    canvas.alpha_composite(fitted, ((canvas_size - fitted.width) // 2, (canvas_size - fitted.height) // 2))
    return canvas


def write_preview(extracted: list[tuple[str, Image.Image]], path: Path) -> None:
    """Inspect the unchanged source colours and cutout edges on light and dark."""
    row_height = canvas_size + 28
    preview = Image.new('RGB', (canvas_size * len(extracted), row_height * 2))
    drawer = ImageDraw.Draw(preview)
    for index, (name, icon) in enumerate(extracted):
        for row, background in enumerate(('#fff3df', '#20283e')):
            x, y = index * canvas_size, row * row_height
            drawer.rectangle((x, y, x + canvas_size - 1, y + row_height - 1), fill=background)
            preview.paste(icon, (x, y), icon)
            drawer.text((x + 16, y + canvas_size + 4), name, fill='#20283e' if row == 0 else '#fff3df')
    preview.save(path)


def main() -> None:
    """Export production sprites and exact extraction provenance for review."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', type=Path, help='Optional light/dark contact sheet.')
    arguments = parser.parse_args()
    source = Image.open(source_path)
    if source.size != source_size or source.mode != 'RGBA':
        raise ValueError(f'Expected the original {source_size} RGBA sheet; got {source.size} {source.mode}.')
    output_dir.mkdir(parents=True, exist_ok=True)
    records = {}
    extracted = []
    for index, name in enumerate(powerup_names):
        original, bounds = extract_source(source, index)
        icon = fit_icon(original)
        path = output_dir / f'{name}.png'
        icon.save(path, optimize=True)
        records[name] = {
            'source_bounds': list(bounds),
            'subject_bounds': list(icon.getbbox()),
            'file': str(path.relative_to(project_root)),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        extracted.append((name, icon))
    metadata = {
        'source': str(source_path.relative_to(project_root)),
        'source_sha256': hashlib.sha256(source_path.read_bytes()).hexdigest(),
        'canvas_size': canvas_size,
        'subject_size': subject_size,
        'method': 'original RGB and alpha; whole-sheet connected-body extraction; two-pixel alpha support; proportional transparent canvas',
        'icons': records,
    }
    (output_dir / 'extract_powerups.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    if arguments.preview:
        write_preview(extracted, arguments.preview)
    print(f'Extracted {len(records)} power-up icons into {output_dir}')


if __name__ == '__main__':
    main()
