"""Full-pipeline synthetic sheet tests that require real cv2 and numpy.

These tests draw complete a4-omr-v4 sheets (markers, bubble rings, fills),
optionally photograph them through a perspective warp, and run the bridge end
to end.  They are skipped (not failed) when OpenCV/NumPy wheels are absent, so
a bare contract-check environment still passes `python -m unittest`.
"""

import json
import tempfile
import unittest
from pathlib import Path

try:
    import cv2
    import numpy as np

    HAVE_CV = True
except ImportError:  # pragma: no cover - depends on environment
    HAVE_CV = False

import paper_omr_bridge as bridge

MARKER_CENTERS = [[150.0, 155.0], [1950.0, 155.0], [150.0, 2725.0], [1950.0, 2725.0]]
QUESTION_COUNT = 20
BUBBLES_GAP = 84
ROW_GAP = 64
ORIGIN = [902, 746]
RING_RADIUS = 20
RING_THICKNESS = 3
FILL_RADIUS = 14


def _template(tmp: str) -> Path:
    path = Path(tmp) / "template.json"
    path.write_text(
        json.dumps(
            {
                "pageDimensions": [2100, 2970],
                "bubbleDimensions": [40, 40],
                "outputColumns": ["q1..%d" % QUESTION_COUNT],
                "fieldBlocks": {
                    "answers_1": {
                        "fieldType": "QTYPE_MCQ5",
                        "fieldLabels": ["q1..%d" % QUESTION_COUNT],
                        "bubblesGap": BUBBLES_GAP,
                        "labelsGap": ROW_GAP,
                        "origin": ORIGIN,
                    }
                },
                "personal_exam_geometry": {
                    "schema_version": 1,
                    "layout": "a4-omr-v4",
                    "marker_centers": MARKER_CENTERS,
                },
            }
        ),
        encoding="utf-8",
    )
    return path


def _bubble_center(question: int, option: int) -> tuple[int, int]:
    x = ORIGIN[0] + option * BUBBLES_GAP
    y = ORIGIN[1] + (question - 1) * ROW_GAP
    return (int(x), int(y))


def _draw_sheet(fills: dict[int, list[int]], light_fills: dict[int, list[int]] | None = None) -> np.ndarray:
    """Render one canonical page; fills map question -> option indexes."""
    light_fills = light_fills or {}
    page = np.full((2970, 2100), 255, dtype=np.uint8)

    def draw_marker(center: tuple[float, float]) -> None:
        x, y = (int(round(value)) for value in center)
        cv2.rectangle(page, (x - 50, y - 50), (x + 50, y + 50), 0, -1)
        cv2.rectangle(page, (x - 23, y - 23), (x + 23, y + 23), 255, -1)
        cv2.rectangle(page, (x - 13, y - 13), (x + 13, y + 13), 0, -1)

    for center in MARKER_CENTERS:
        draw_marker((center[0], center[1]))
    for question in range(1, QUESTION_COUNT + 1):
        for option in range(5):
            x, y = _bubble_center(question, option)
            cv2.circle(page, (x, y), RING_RADIUS, 0, RING_THICKNESS)
            if option in fills.get(question, []):
                cv2.circle(page, (x, y), FILL_RADIUS, 0, -1)
            elif option in light_fills.get(question, []):
                # A light pencil mark: dark enough to read as ink on paper but
                # clearly below the bridge's selection floor of 105.
                cv2.circle(page, (x, y), FILL_RADIUS, 170, -1)
    return page


def _photograph(page: np.ndarray) -> np.ndarray:
    """Perspective-warp the canonical page like a phone photo would."""
    source = np.float32([[0, 0], [2100, 0], [2100, 2970], [0, 2970]])
    photographed = np.float32([[80, 90], [1320, 130], [1260, 1730], [110, 1660]])
    return cv2.warpPerspective(
        page,
        cv2.getPerspectiveTransform(source, photographed),
        (1400, 1800),
        borderValue=180,
    )


@unittest.skipUnless(HAVE_CV, "real cv2/numpy are required for synthetic sheet tests")
class SyntheticSheetTest(unittest.TestCase):
    maxDiff = None

    def _run_bridge(self, image_path: Path, template_path: Path) -> dict:
        with tempfile.TemporaryDirectory() as out_root:
            output = Path(out_root) / "result.json"
            result = bridge.run(image_path, template_path, output)
            self.assertEqual(output.exists(), True)
            reread = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(reread, result)
        return result

    def test_empty_single_multiple_and_full_fills(self) -> None:
        fills = {
            1: [0],  # A
            2: [1, 2],  # B, C (multiple)
            3: [],  # unanswered
            4: [0, 1, 2, 3, 4],  # fully filled
            5: [4],  # E
        }
        page = _draw_sheet(fills)
        with tempfile.TemporaryDirectory() as root:
            template = _template(root)
            image = Path(root) / "sheet.png"
            self.assertTrue(cv2.imwrite(str(image), page))
            result = self._run_bridge(image, template)
        self.assertEqual(result["layout"], "a4-omr-v4")
        self.assertEqual(result["source_size"], {"width": 2100, "height": 2970})
        self.assertEqual(len(result["questions"]), QUESTION_COUNT)
        by_label = {row["label"]: row["selected"] for row in result["questions"]}
        self.assertEqual(by_label["q1"], ["A"])
        self.assertEqual(by_label["q2"], ["B", "C"])
        self.assertEqual(by_label["q3"], [])
        self.assertEqual(by_label["q4"], ["A", "B", "C", "D", "E"])
        self.assertEqual(by_label["q5"], ["E"])
        self.assertEqual(by_label["q6"], [])
        self.assertEqual(by_label["q20"], [])
        for row in result["questions"]:
            self.assertEqual(row["confidence"], 0.0)
            self.assertEqual(len(row["bubble_quad"]), 5)

    def test_light_fill_is_not_selected(self) -> None:
        page = _draw_sheet({}, light_fills={1: [0, 1]})
        with tempfile.TemporaryDirectory() as root:
            template = _template(root)
            image = Path(root) / "light.png"
            self.assertTrue(cv2.imwrite(str(image), page))
            result = self._run_bridge(image, template)
        by_label = {row["label"]: row["selected"] for row in result["questions"]}
        self.assertEqual(by_label["q1"], [])

    def test_photographed_perspective_is_recognized(self) -> None:
        fills = {1: [0], 7: [2, 3], 20: [1]}
        page = _draw_sheet(fills)
        photo = _photograph(page)
        with tempfile.TemporaryDirectory() as root:
            template = _template(root)
            image = Path(root) / "photo.png"
            self.assertTrue(cv2.imwrite(str(image), photo))
            result = self._run_bridge(image, template)
        self.assertEqual(result["source_size"], {"width": 1400, "height": 1800})
        by_label = {row["label"]: row["selected"] for row in result["questions"]}
        self.assertEqual(by_label["q1"], ["A"])
        self.assertEqual(by_label["q7"], ["C", "D"])
        self.assertEqual(by_label["q20"], ["B"])
        self.assertEqual(by_label["q10"], [])

    def test_jpeg_input_is_supported(self) -> None:
        page = _draw_sheet({2: [3]})
        with tempfile.TemporaryDirectory() as root:
            template = _template(root)
            image = Path(root) / "sheet.jpg"
            self.assertTrue(cv2.imwrite(str(image), page, [cv2.IMWRITE_JPEG_QUALITY, 92]))
            result = self._run_bridge(image, template)
        by_label = {row["label"]: row["selected"] for row in result["questions"]}
        self.assertEqual(by_label["q2"], ["D"])

    def test_self_test_geometry_checks_pass(self) -> None:
        bridge.run_synthetic_geometry_checks()


if __name__ == "__main__":
    unittest.main()
