"""Contract tests that run without real cv2/numpy (module stubs)."""

import json
import sys
import tempfile
import types
import unittest
from pathlib import Path

# Only stub cv2/numpy when the real wheels are unavailable; a stub registered
# unconditionally would leak into sibling test modules in the same process.
try:
    import cv2  # noqa: F401
    import numpy  # noqa: F401
except ImportError:
    sys.modules.setdefault("cv2", types.ModuleType("cv2"))
    sys.modules.setdefault("numpy", types.ModuleType("numpy"))

import paper_omr_bridge as bridge


class GeometryContractTest(unittest.TestCase):
    def test_template_bubble_gap_drives_all_five_centers(self) -> None:
        for gap in (84, 74, 56):
            with self.subTest(gap=gap), tempfile.TemporaryDirectory() as root:
                template = Path(root) / "template.json"
                template.write_text(
                    json.dumps(
                        {
                            "pageDimensions": [2100, 2970],
                            "bubbleDimensions": [40, 40],
                            "fieldBlocks": {
                                "answers_1": {
                                    "fieldType": "QTYPE_MCQ5",
                                    "fieldLabels": ["q1..1"],
                                    "bubblesGap": gap,
                                    "labelsGap": 64,
                                    "origin": [238, 746],
                                }
                            },
                            "personal_exam_geometry": {
                                "schema_version": 1,
                                "layout": "a4-omr-v4",
                                "marker_centers": [
                                    [150, 155],
                                    [1950, 155],
                                    [150, 2725],
                                    [1950, 2725],
                                ],
                            },
                        }
                    ),
                    encoding="utf-8",
                )

                _width, _height, _markers, bubbles = bridge._load_contract(
                    template
                )
                self.assertEqual(bubbles, [("q1", 238.0, 746.0, float(gap))])
                self.assertEqual(
                    bridge._expected_bubble_centers(bubbles[0]),
                    [(238.0 + option * gap, 746.0) for option in range(5)],
                )

    def test_contract_rejects_foreign_geometry(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            template = Path(root) / "template.json"
            document = {
                "pageDimensions": [2100, 2970],
                "bubbleDimensions": [40, 40],
                "fieldBlocks": {
                    "answers_1": {
                        "fieldType": "QTYPE_MCQ5",
                        "fieldLabels": ["q1..1"],
                        "bubblesGap": 84,
                        "labelsGap": 64,
                        "origin": [238, 746],
                    }
                },
                "personal_exam_geometry": {
                    "schema_version": 1,
                    "layout": "a4-omr-v3",
                    "marker_centers": [
                        [150, 155],
                        [1950, 155],
                        [150, 2725],
                        [1950, 2725],
                    ],
                },
            }
            template.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaises(ValueError):
                bridge._load_contract(template)

    def test_contract_rejects_wrong_page_size(self) -> None:
        with tempfile.TemporaryDirectory() as root:
            template = Path(root) / "template.json"
            document = {
                "pageDimensions": [1000, 1400],
                "bubbleDimensions": [40, 40],
                "fieldBlocks": {
                    "answers_1": {
                        "fieldType": "QTYPE_MCQ5",
                        "fieldLabels": ["q1..1"],
                        "bubblesGap": 84,
                        "labelsGap": 64,
                        "origin": [238, 746],
                    }
                },
                "personal_exam_geometry": {
                    "schema_version": 1,
                    "layout": "a4-omr-v4",
                    "marker_centers": [
                        [150, 155],
                        [1950, 155],
                        [150, 2725],
                        [1950, 2725],
                    ],
                },
            }
            template.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaises(ValueError):
                bridge._load_contract(template)

    def test_input_extension_allowlist(self) -> None:
        self.assertEqual(bridge.ALLOWED_EXTENSIONS, {".png", ".jpg", ".jpeg"})


if __name__ == "__main__":
    unittest.main()
