"""Standalone Windows sidecar for a4-omr-v4 paper answer-sheet scanning.

The executable made from this module takes exactly one PNG/JPG/JPEG and one
template.json, then emits a small, versioned result document.  It only uses
cv2, numpy and the standard library.  It does not accept PDFs and has no
PyMuPDF import or dependency.

The `confidence` field is a reserved contract field: this implementation does
not estimate a selection probability and always reports 0.0.  Callers must
treat it as "not estimated" and rely on the human review step; they must not
display it as a real probability.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path

import cv2
import numpy as np

ALLOWED_EXTENSIONS = {".png", ".jpg", ".jpeg"}


SCHEMA_VERSION = 2
LAYOUT = "a4-omr-v4"
OPTIONS = "ABCDE"


def _require_number(value: object, name: str) -> float:
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f"{name} must be finite")
    return float(value)


def _load_contract(
    template_path: Path,
) -> tuple[int, int, list[list[float]], list[tuple[str, float, float, float]]]:
    """Read only the geometry that the a4-omr-v4 exporter owns.

    This deliberately rejects foreign geometry templates: falling back to
    another sheet layout would make a scan look successful while reading the
    wrong bubbles.
    """
    try:
        template = json.loads(template_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError("template JSON is invalid") from error
    geometry = template.get("personal_exam_geometry")
    if not isinstance(geometry, dict) or geometry.get("schema_version") != 1:
        raise ValueError("a4-omr-v4 geometry contract is missing")
    if geometry.get("layout") != LAYOUT:
        raise ValueError("unsupported answer sheet layout")
    dimensions = template.get("pageDimensions")
    if dimensions != [2100, 2970]:
        raise ValueError("a4-omr-v4 page dimensions must be 2100x2970")
    centers = geometry.get("marker_centers")
    if not isinstance(centers, list) or len(centers) != 4:
        raise ValueError("a4-omr-v4 requires four marker centers")
    marker_centers: list[list[float]] = []
    for index, point in enumerate(centers):
        if not isinstance(point, list) or len(point) != 2:
            raise ValueError(f"marker center {index + 1} is invalid")
        marker_centers.append([
            _require_number(point[0], "marker x"),
            _require_number(point[1], "marker y"),
        ])
    if marker_centers != [[150.0, 155.0], [1950.0, 155.0], [150.0, 2725.0], [1950.0, 2725.0]]:
        raise ValueError("a4-omr-v4 marker geometry does not match this bridge")

    if template.get("bubbleDimensions") != [40, 40]:
        raise ValueError("a4-omr-v4 bubble dimensions must be 40x40")
    blocks = template.get("fieldBlocks")
    if not isinstance(blocks, dict) or not blocks:
        raise ValueError("a4-omr-v4 field blocks are missing")
    bubbles: list[tuple[str, float, float, float]] = []
    for block in blocks.values():
        if not isinstance(block, dict):
            raise ValueError("field block is invalid")
        labels = block.get("fieldLabels")
        origin = block.get("origin")
        gap = block.get("bubblesGap")
        row_gap = block.get("labelsGap")
        if (not isinstance(labels, list) or len(labels) != 1 or
                not isinstance(labels[0], str) or not isinstance(origin, list) or len(origin) != 2):
            raise ValueError("field block geometry is invalid")
        match = re.fullmatch(r"q([1-9]\d*)\.\.(?:q)?([1-9]\d*)", labels[0])
        if not match:
            raise ValueError("field block labels must be qN..qM")
        first, last = int(match.group(1)), int(match.group(2))
        if last < first:
            raise ValueError("field block label range is invalid")
        x = _require_number(origin[0], "bubble origin x")
        y = _require_number(origin[1], "bubble origin y")
        gap = _require_number(gap, "bubble gap")
        row_gap = _require_number(row_gap, "row gap")
        for number in range(first, last + 1):
            bubbles.append((f"q{number}", x, y + (number - first) * row_gap, gap))
    bubbles.sort(key=lambda row: int(row[0][1:]))
    if [label for label, _, _, _ in bubbles] != [
        f"q{i}" for i in range(1, len(bubbles) + 1)
    ]:
        raise ValueError("question labels must be complete and consecutive")
    return 2100, 2970, marker_centers, bubbles


def _order_quad(points: np.ndarray) -> np.ndarray:
    """Return TL, TR, BR, BL points for OpenCV homography calls."""
    ordered = np.zeros((4, 2), dtype=np.float32)
    sums = points.sum(axis=1)
    diffs = np.diff(points, axis=1).reshape(-1)
    ordered[0] = points[np.argmin(sums)]
    ordered[2] = points[np.argmax(sums)]
    ordered[1] = points[np.argmin(diffs)]
    ordered[3] = points[np.argmax(diffs)]
    return ordered


def _marker_candidates(gray: np.ndarray) -> list[np.ndarray]:
    """Find outer squares which contain at least two nested square rings."""
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _threshold, binary = cv2.threshold(
        blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
    )
    contours, hierarchy = cv2.findContours(binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    if hierarchy is None:
        return []
    hierarchy = hierarchy[0]
    minimum_side = min(gray.shape[:2]) * 0.020
    candidates: list[np.ndarray] = []
    for index, contour in enumerate(contours):
        area = cv2.contourArea(contour)
        if area <= 0:
            continue
        rectangle = cv2.minAreaRect(contour)
        width, height = rectangle[1]
        if (min(width, height) < minimum_side or
                max(width, height) > min(gray.shape[:2]) * 0.12 or
                max(width, height) / min(width, height) > 1.35):
            continue
        perimeter = cv2.arcLength(contour, True)
        polygon = cv2.approxPolyDP(contour, 0.045 * perimeter, True)
        if len(polygon) != 4 or area / (width * height) < 0.65:
            continue
        # An a4-omr-v4 marker is black / white / black.  Requiring a child and
        # grandchild removes answer bubbles and ordinary document rectangles.
        child = hierarchy[index][2]
        grandchild = hierarchy[child][2] if child >= 0 else -1
        if child < 0 or grandchild < 0:
            continue
        candidates.append(_order_quad(polygon.reshape(4, 2).astype(np.float32)))
    # Threshold contours can describe both the outer black ring and a nested
    # ring of the same marker.  Keep one candidate per physical marker before
    # quadrant cardinality is checked; separate markers remain far apart.
    unique: list[np.ndarray] = []
    for candidate in sorted(
        candidates,
        key=lambda quad: cv2.contourArea(quad.reshape((-1, 1, 2))),
        reverse=True,
    ):
        center = candidate.mean(axis=0)
        if all(np.linalg.norm(center - existing.mean(axis=0)) >= minimum_side for existing in unique):
            unique.append(candidate)
    return unique


def _find_page_quad(gray: np.ndarray, marker_centers: list[list[float]]) -> np.ndarray:
    candidates = _marker_candidates(gray)
    height, width = gray.shape[:2]
    buckets: list[list[np.ndarray]] = [[], [], [], []]
    for candidate in candidates:
        center = candidate.mean(axis=0)
        right = center[0] >= width / 2
        bottom = center[1] >= height / 2
        bucket = (1 if right else 0) + (2 if bottom else 0)
        buckets[bucket].append(candidate)
    if any(len(bucket) != 1 for bucket in buckets):
        counts = ", ".join(str(len(bucket)) for bucket in buckets)
        raise RuntimeError(f"a4-omr-v4 marker detection is missing or ambiguous ({counts})")
    # Bucket order is TL, TR, BL, BR; homography expects perimeter order.
    source_centers = np.array([bucket[0].mean(axis=0) for bucket in buckets], dtype=np.float32)
    source = np.array([source_centers[0], source_centers[1], source_centers[3], source_centers[2]], dtype=np.float32)
    target = np.array([marker_centers[0], marker_centers[1], marker_centers[3], marker_centers[2]], dtype=np.float32)
    if cv2.contourArea(source.reshape((-1, 1, 2))) < width * height * 0.10:
        raise RuntimeError("a4-omr-v4 markers do not span a valid page")
    return source


def _normalise_quad(points: np.ndarray, width: int, height: int) -> list[list[float]]:
    return [[round(float(x) / width, 8), round(float(y) / height, 8)] for x, y in points]


def _bubble_quad(x: float, y: float, inverse: np.ndarray, width: int, height: int) -> list[list[float]]:
    points = np.array([[[x - 20, y - 20], [x + 20, y - 20], [x + 20, y + 20], [x - 20, y + 20]]], dtype=np.float32)
    original = cv2.perspectiveTransform(points, inverse)[0]
    result = _normalise_quad(original, width, height)
    if any(value < 0 or value > 1 for point in result for value in point):
        raise RuntimeError("projected bubble geometry lies outside the source image")
    return result


def _expected_bubble_centers(
    bubble: tuple[str, float, float, float],
) -> list[tuple[float, float]]:
    _label, x, y, gap = bubble
    return [(x + index * gap, y) for index in range(len(OPTIONS))]


def _refine_bubble_centers(
    warped: np.ndarray, bubbles: list[tuple[str, float, float, float]]
) -> dict[str, list[tuple[float, float]]]:
    """Snap template centers to the printed rings after the page warp.

    The four markers solve perspective globally.  A real sheet can still have
    slight curl, so this local refinement prevents a 20px sampling mask from
    landing between a ring and its fill in the lower/right grid groups.
    """
    circles = cv2.HoughCircles(
        warped,
        cv2.HOUGH_GRADIENT,
        dp=1.2,
        minDist=30,
        param1=100,
        param2=22,
        minRadius=15,
        maxRadius=28,
    )
    if circles is None:
        raise RuntimeError("a4-omr-v4 bubble rings cannot be detected")
    detected = [(float(x), float(y)) for x, y, _radius in circles[0]]

    # Chromium's printed CSS grid can be shifted, scaled and sheared slightly
    # relative to the nominal template coordinates (printer margins are not
    # involved in the four-marker homography).  Estimate an order-preserving
    # initial mapping from the repeated bubble columns/rows, then refine it to
    # a full affine transform.  Preserving column order matters: an ordinary
    # nearest-neighbour fit can align template A to printed B and still appear
    # numerically convincing.
    expected_points = [
        point
        for bubble in bubbles
        for point in _expected_bubble_centers(bubble)
    ]
    expected_xs = sorted({point[0] for point in expected_points})
    expected_ys = sorted({point[1] for point in expected_points})

    table_points = [
        point for point in detected
        if expected_xs[0] - 150 <= point[0] <= expected_xs[-1] + 150
        and expected_ys[0] - 150 <= point[1] <= expected_ys[-1] + 150
    ]
    source_matches: list[tuple[float, float]] = []
    target_matches: list[tuple[float, float]] = []
    group_source_matches: list[list[tuple[float, float]]] = [
        [] for _ in range(len(expected_xs) // 5)
    ]
    group_target_matches: list[list[tuple[float, float]]] = [
        [] for _ in range(len(expected_xs) // 5)
    ]
    # Build physical row bands before assigning columns.  Within one row the
    # five bubbles are ordered unambiguously even when the photographed paper
    # is curled and the grid is sheared.  A question-number glyph can sometimes
    # look circular to Hough; it is left of A, so the last five members of a
    # six-cell group remain the answer bubbles.
    row_bands: list[list[tuple[float, float]]] = []
    for point in sorted(table_points, key=lambda item: item[1]):
        if not row_bands or point[1] - row_bands[-1][-1][1] > 9:
            row_bands.append([point])
        else:
            row_bands[-1].append(point)
    row_bands = sorted(row_bands, key=len, reverse=True)[:len(expected_ys)]
    row_bands.sort(key=lambda band: float(np.median([point[1] for point in band])))
    group_count = len(expected_xs) // 5
    for row_index, band in enumerate(row_bands):
        column_groups: list[list[tuple[float, float]]] = []
        for point in sorted(band, key=lambda item: item[0]):
            if not column_groups or point[0] - column_groups[-1][-1][0] > 90:
                column_groups.append([point])
            else:
                column_groups[-1].append(point)
        usable_groups = [group for group in column_groups if len(group) >= 5]
        for group_index, group in enumerate(usable_groups[:group_count]):
            answer_points = sorted(group, key=lambda item: item[0])[-5:]
            for option_index, actual in enumerate(answer_points):
                expected_column = group_index * 5 + option_index
                expected = (expected_xs[expected_column], expected_ys[row_index])
                source_matches.append(expected)
                target_matches.append(actual)
                group_source_matches[group_index].append(expected)
                group_target_matches[group_index].append(actual)
    if len(source_matches) < max(4, min(20, len(bubbles))):
        raise RuntimeError("a4-omr-v4 bubble lattice has too few reliable circles")
    affine, _inliers = cv2.estimateAffine2D(
        np.asarray(source_matches, dtype=np.float32),
        np.asarray(target_matches, dtype=np.float32),
        method=cv2.RANSAC,
        ransacReprojThreshold=6.0,
    )
    if affine is None:
        raise RuntimeError("a4-omr-v4 bubble lattice alignment failed")

    group_affines: list[np.ndarray | None] = []
    for sources, targets in zip(group_source_matches, group_target_matches):
        local = None
        if len(sources) >= 10:
            local, _local_inliers = cv2.estimateAffine2D(
                np.asarray(sources, dtype=np.float32),
                np.asarray(targets, dtype=np.float32),
                method=cv2.RANSAC,
                ransacReprojThreshold=5.0,
            )
        group_affines.append(local)

    def projected(
        point: tuple[float, float], group_index: int
    ) -> tuple[float, float]:
        transform = group_affines[group_index]
        if transform is None:
            transform = affine
        vector = transform @ np.array([point[0], point[1], 1.0], dtype=np.float64)
        return (float(vector[0]), float(vector[1]))

    def snapped(predicted: tuple[float, float]) -> tuple[float, float]:
        choices = [
            candidate for candidate in detected
            if math.hypot(candidate[0] - predicted[0], candidate[1] - predicted[1]) <= 15
        ]
        if not choices:
            # Filled bubbles are not guaranteed to produce a Hough circle.  In
            # that case the fitted lattice center is more reliable than failing
            # the whole sheet or snapping to nearby text/table contours.
            return predicted
        return min(
            choices,
            key=lambda candidate: math.hypot(
                candidate[0] - predicted[0], candidate[1] - predicted[1]
            ),
        )

    refined: dict[str, list[tuple[float, float]]] = {}
    for bubble_index, bubble in enumerate(bubbles):
        label = bubble[0]
        group_index = bubble_index // 20
        predicted_row = [
            projected(point, group_index)
            for point in _expected_bubble_centers(bubble)
        ]
        residuals: list[tuple[float, float]] = []
        for predicted in predicted_row:
            choices = [
                candidate for candidate in detected
                if math.hypot(
                    candidate[0] - predicted[0], candidate[1] - predicted[1]
                ) <= 30
            ]
            if choices:
                actual = min(
                    choices,
                    key=lambda candidate: math.hypot(
                        candidate[0] - predicted[0], candidate[1] - predicted[1]
                    ),
                )
                residuals.append(
                    (actual[0] - predicted[0], actual[1] - predicted[1])
                )
        if len(residuals) >= 2:
            shift_x = float(np.median([item[0] for item in residuals]))
            shift_y = float(np.median([item[1] for item in residuals]))
            predicted_row = [
                (point[0] + shift_x, point[1] + shift_y)
                for point in predicted_row
            ]
        row = [snapped(point) for point in predicted_row]
        if any(row[index][0] <= row[index - 1][0] + 20 for index in range(1, len(row))):
            raise RuntimeError(f"a4-omr-v4 bubble geometry is invalid for {label}")
        refined[label] = row
    return refined


def _selected_options(warped: np.ndarray, centers: list[tuple[float, float]]) -> list[str]:
    """Score the dark ink inside each canonical bubble, excluding its outline."""
    scores: list[float] = []
    for index, (center_x, center_y) in enumerate(centers):
        center_x = int(round(center_x))
        center_y = int(round(center_y))
        radius = 12
        crop = warped[center_y - radius:center_y + radius + 1, center_x - radius:center_x + radius + 1]
        if crop.shape != (radius * 2 + 1, radius * 2 + 1):
            raise RuntimeError("bubble is outside the corrected page")
        mask = np.zeros(crop.shape, dtype=np.uint8)
        cv2.circle(mask, (radius, radius), 8, 255, -1)
        scores.append(float(255 - cv2.mean(crop, mask=mask)[0]))
    # Printed empty circles score below 100 after excluding the rim; a filled
    # circle is markedly darker.  Do not derive this from the row median: a
    # multiple-choice response may legitimately fill three of its five cells.
    floor = 105.0
    return [OPTIONS[index] for index, score in enumerate(scores) if score >= floor]


def run(input_path: Path, template_path: Path, output_path: Path) -> dict[str, object]:
    if input_path.suffix.lower() not in ALLOWED_EXTENSIONS:
        raise ValueError("only PNG/JPG/JPEG input is supported")
    if not input_path.is_file() or not template_path.is_file():
        raise FileNotFoundError("input image or template is missing")
    page_width, page_height, marker_centers, bubbles = _load_contract(template_path)
    color = cv2.imread(str(input_path), cv2.IMREAD_COLOR)
    if color is None:
        raise ValueError("input image cannot be decoded")
    gray = cv2.cvtColor(color, cv2.COLOR_BGR2GRAY)
    source_height, source_width = gray.shape
    page_quad = _find_page_quad(gray, marker_centers)
    target_quad = np.array(
        [marker_centers[0], marker_centers[1], marker_centers[3], marker_centers[2]], dtype=np.float32
    )
    homography = cv2.getPerspectiveTransform(page_quad, target_quad)
    inverse = cv2.getPerspectiveTransform(target_quad, page_quad)
    warped = cv2.warpPerspective(gray, homography, (page_width, page_height), flags=cv2.INTER_CUBIC)
    refined_centers = _refine_bubble_centers(warped, bubbles)
    questions = []
    for label, _x, _y, _gap in bubbles:
        centers = refined_centers[label]
        questions.append(
            {
                "label": label,
                "selected": _selected_options(warped, centers),
                "confidence": 0.0,
                "bubble_quad": {
                    option: _bubble_quad(center_x, center_y, inverse, source_width, source_height)
                    for option, (center_x, center_y) in zip(OPTIONS, centers)
                },
            }
        )
    result = {
        "schema_version": SCHEMA_VERSION,
        "layout": LAYOUT,
        "source_size": {"width": source_width, "height": source_height},
        "page_quad": _normalise_quad(page_quad, source_width, source_height),
        "questions": questions,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
    return result


def _synthetic_marker_page(
    marker_centers: list[list[float]], *, missing: int | None = None, duplicate: bool = False
) -> np.ndarray:
    """Generate a perspective-only marker fixture for bridge geometry checks."""
    page = np.full((2970, 2100), 255, dtype=np.uint8)

    def draw_marker(center: tuple[float, float]) -> None:
        x, y = (int(round(value)) for value in center)
        cv2.rectangle(page, (x - 50, y - 50), (x + 50, y + 50), 0, -1)
        cv2.rectangle(page, (x - 23, y - 23), (x + 23, y + 23), 255, -1)
        cv2.rectangle(page, (x - 13, y - 13), (x + 13, y + 13), 0, -1)

    for index, center in enumerate(marker_centers):
        if index != missing:
            draw_marker((center[0], center[1]))
    if duplicate:
        draw_marker((marker_centers[0][0] + 300, marker_centers[0][1]))
    source = np.float32([[0, 0], [2100, 0], [2100, 2970], [0, 2970]])
    photographed = np.float32([[80, 90], [1320, 130], [1260, 1730], [110, 1660]])
    return cv2.warpPerspective(page, cv2.getPerspectiveTransform(source, photographed), (1400, 1800), borderValue=180)


def run_synthetic_geometry_checks() -> None:
    """Verify the acceptance boundary: perspective passes; missing/duplicate fails."""
    centers = [[150.0, 155.0], [1950.0, 155.0], [150.0, 2725.0], [1950.0, 2725.0]]
    _find_page_quad(_synthetic_marker_page(centers), centers)
    for fixture in (
        _synthetic_marker_page(centers, missing=3),
        _synthetic_marker_page(centers, duplicate=True),
    ):
        try:
            _find_page_quad(fixture, centers)
        except RuntimeError:
            continue
        raise AssertionError("invalid synthetic marker geometry unexpectedly passed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path)
    parser.add_argument("--template", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            if args.input or args.template or args.output:
                raise ValueError("--self-test does not accept scan arguments")
            run_synthetic_geometry_checks()
            print("synthetic geometry checks passed")
            return 0
        if not args.input or not args.template or not args.output:
            raise ValueError("--input, --template, and --output are required")
        result = run(args.input, args.template, args.output)
    except Exception as error:  # bridge boundary: message becomes Dart stderr.
        print(f"paper_omr_bridge: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
