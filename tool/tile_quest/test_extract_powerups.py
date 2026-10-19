"""Regression checks for cutting the original power-up sheet without redrawing."""
import hashlib
import io
import json
import unittest

import numpy as np
from PIL import Image

import extract_powerups as extraction


class powerup_extraction_test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = Image.open(extraction.source_path)
        cls.metadata = json.loads((extraction.output_dir / 'extract_powerups.json').read_text())
        cls.originals = [extraction.extract_source(cls.source, index) for index in range(3)]

    def test_original_sheet_unchanged(self):
        self.assertEqual(self.source.mode, 'RGBA')
        self.assertEqual(self.source.size, extraction.source_size)
        self.assertEqual(hashlib.sha256(extraction.source_path.read_bytes()).hexdigest(), self.metadata['source_sha256'])
        self.assertEqual(self.metadata['source_sha256'], '294f5d4bed3336376fc74f85b2f82e07497a2d1c2ace5c8a0adf27232e37a567')

    def test_generated_pngs_are_reproducible_and_proportionate(self):
        for name, (original, bounds) in zip(extraction.powerup_names, self.originals):
            with self.subTest(name=name):
                fitted = extraction.fit_icon(original)
                encoded = io.BytesIO()
                fitted.save(encoded, format='PNG', optimize=True)
                production = (extraction.output_dir / f'{name}.png').read_bytes()
                self.assertEqual(encoded.getvalue(), production)
                self.assertEqual(list(bounds), self.metadata['icons'][name]['source_bounds'])
                self.assertEqual(hashlib.sha256(production).hexdigest(), self.metadata['icons'][name]['sha256'])
                self.assertEqual(fitted.size, (256, 256))
                alpha = np.asarray(fitted.getchannel('A'))
                self.assertEqual(int(alpha[0, :].sum() + alpha[-1, :].sum() + alpha[:, 0].sum() + alpha[:, -1].sum()), 0)
                opaque = Image.fromarray(np.where(alpha > 127, 255, 0).astype(np.uint8)).getbbox()
                self.assertTrue(220 <= max(opaque[2] - opaque[0], opaque[3] - opaque[1]) <= 224)

    def test_original_colours_alpha_and_negative_spaces_survive(self):
        for name, (original, bounds) in zip(extraction.powerup_names, self.originals):
            with self.subTest(name=name):
                source_crop = np.asarray(self.source.crop(bounds))
                cleaned = np.asarray(original)
                visible = cleaned[:, :, 3] > 0
                self.assertTrue(np.array_equal(cleaned[:, :, :3][visible], source_crop[:, :, :3][visible]))
                self.assertTrue(np.array_equal(cleaned[:, :, 3][visible], source_crop[:, :, 3][visible]))
                self.assertFalse(np.any(cleaned[:, :, 3][source_crop[:, :, 3] == 0]))
        # The curl and the two-arrow crossover have meaningful transparent
        # interiors.  Their central gaps must never become opaque rectangles.
        self.assertEqual(self.originals[0][0].getpixel((370 - 23, 460 - 55))[3], 0)
        self.assertEqual(self.originals[1][0].getpixel((1200 - 721, 380 - 47))[3], 0)

    def test_shuffle_is_not_clipped_at_equal_sheet_thirds(self):
        self.assertGreater(self.originals[1][1][2], self.source.width * 2 // 3)
        for original, bounds in self.originals:
            self.assertGreater(original.getchannel('A').getextrema()[1], 250)
            self.assertLess(bounds[1], self.source.height // 10)


if __name__ == '__main__':
    unittest.main()
