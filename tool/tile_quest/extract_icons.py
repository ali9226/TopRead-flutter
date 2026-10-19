#!/usr/bin/env python3
"""Extract the user's fifteen original illustrations without redrawing them.

Usage: python3 tool/tile_quest/extract_icons.py --preview /tmp/tile_icons.png
Requires Pillow and numpy.  The input sheet is RGBA: its transparent pixels still
contain the old coloured background in RGB, so preserving alpha is essential.
The script removes isolated alpha noise, retains the source's antialiasing and
negative spaces, and fits each original illustration on a 256×256 transparent
canvas.  The input sheet and the supplied lattice background are never modified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

project_root = Path(__file__).resolve().parents[2]
source_path = project_root / 'assets/img/tile_quest/1.png'
output_dir = project_root / 'assets/img/tile_quest/icons'
canvas_size = 256
subject_size = 216
solid_alpha_threshold = 127
noise_alpha_threshold = 12
source_opaque_alpha = 253

# Generous individual rectangles avoid clipping leaves, stems and tool handles
# that do not fit a regular 5×3 grid cell.  Coordinates refer to the original.
source_rects = {
    'mushroom': (60, 60, 355, 355),
    'carrot': (375, 40, 640, 355),
    'watermelon': (625, 60, 935, 355),
    'lemon': (930, 60, 1220, 355),
    'shovel': (1210, 50, 1490, 360),
    'glove': (45, 360, 340, 670),
    'leaf': (350, 365, 610, 670),
    'strawberry': (615, 355, 890, 670),
    'milk_bottle': (900, 340, 1175, 680),
    'scissors': (1180, 360, 1500, 670),
    'hay': (35, 670, 330, 975),
    'yarn': (330, 670, 635, 975),
    'star': (610, 670, 915, 975),
    'grapes': (910, 665, 1210, 975),
    'snowflake': (1200, 655, 1510, 985),
}


def clean_alpha(source_alpha: Image.Image) -> Image.Image:
    """Retain the central illustration's connected body and antialiased fringe.

    Selecting only its connected component rejects isolated coloured specks in
    the supplied sheet.  A one-pixel support band preserves fractional edge
    coverage.  Existing openings in the shovel and scissors stay transparent.
    """
    alpha = np.asarray(source_alpha, dtype=np.uint8)
    solid_y, solid_x = np.nonzero(alpha > solid_alpha_threshold)
    if not len(solid_x):
        raise ValueError('The source rectangle contains no opaque illustration.')
    center_x = (alpha.shape[1]-1)/2
    center_y = (alpha.shape[0]-1)/2
    distances = (solid_x-center_x)**2 + (solid_y-center_y)**2
    seed_index = int(distances.argmin())
    seed = (int(solid_x[seed_index]), int(solid_y[seed_index]))
    connected = Image.fromarray(np.where(alpha > solid_alpha_threshold, 255, 0).astype(np.uint8)).copy()
    ImageDraw.floodfill(connected, seed, 128, thresh=0)
    component = Image.fromarray(np.where(np.asarray(connected) == 128, 255, 0).astype(np.uint8))
    support = np.asarray(component.filter(ImageFilter.MaxFilter(3))) > 0
    cleaned = np.where(support & (alpha >= noise_alpha_threshold), alpha, 0)
    # The supplied sheet's solid pixels are alpha 252–254.  Normalize that tiny
    # global opacity loss, while preserving genuinely fractional edge coverage.
    cleaned = np.minimum(np.rint(cleaned.astype(np.float32)*255/source_opaque_alpha), 255).astype(np.uint8)
    return Image.fromarray(cleaned)


def extract_icon(source: Image.Image, bounds: tuple[int, int, int, int]) -> Image.Image:
    """Keep source colours intact and center the fitted, proportional silhouette."""
    image = source.crop(bounds)
    image.putalpha(clean_alpha(image.getchannel('A')))
    image = image.crop(image.getbbox())
    scale = subject_size/max(image.size)
    image = image.resize((round(image.width*scale), round(image.height*scale)), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (canvas_size, canvas_size))
    canvas.alpha_composite(image, ((canvas_size-image.width)//2, (canvas_size-image.height)//2))
    return canvas


def write_preview(extracted: list[tuple[str, Image.Image]], path: Path) -> None:
    """Render every alpha edge on both the tile-face and dark-board backgrounds."""
    columns = 5
    row_height = 280
    rows_per_background = 3
    preview = Image.new('RGB', (columns*canvas_size, rows_per_background*2*row_height))
    drawer = ImageDraw.Draw(preview)
    for index, (name, image) in enumerate(extracted):
        for background_index, background in enumerate(('#fff3df', '#20283e')):
            x = (index%columns)*canvas_size
            y = (index//columns+background_index*rows_per_background)*row_height
            drawer.rectangle((x, y, x+canvas_size-1, y+row_height-1), fill=background)
            preview.paste(image, (x, y), image)
            drawer.text((x+12, y+258), name, fill='#111111' if background_index == 0 else '#ffffff')
    preview.save(path)


def main() -> None:
    """Write exactly fifteen production sprites and reproducible source metadata."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', type=Path, help='Optional light/dark contact sheet output.')
    arguments = parser.parse_args()
    source = Image.open(source_path)
    if source.size != (1536, 1024) or source.mode != 'RGBA':
        raise ValueError(f'The source must be the original 1536×1024 RGBA sheet; got {source.size} {source.mode}.')
    output_dir.mkdir(parents=True, exist_ok=True)
    records = {}
    extracted = []
    for name, bounds in source_rects.items():
        image = extract_icon(source, bounds)
        path = output_dir/f'tile_{name}.png'
        image.save(path, optimize=True)
        records[name] = {
            'source_bounds': list(bounds),
            'subject_bounds': list(image.getbbox()),
            'file': str(path.relative_to(project_root)),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        extracted.append((name, image))
    metadata = {
        'source': str(source_path.relative_to(project_root)),
        'source_sha256': hashlib.sha256(source_path.read_bytes()).hexdigest(),
        'canvas_size': canvas_size,
        'subject_size': subject_size,
        'method': 'original source RGB and alpha; connected-body alpha noise cleanup; proportional transparent canvas',
        'icons': records,
    }
    (output_dir/'extract_icons.json').write_text(json.dumps(metadata, indent=2)+'\n', encoding='utf-8')
    if arguments.preview:
        write_preview(extracted, arguments.preview)
    print(f'Extracted {len(records)} transparent icons into {output_dir}')


if __name__ == '__main__':
    main()
