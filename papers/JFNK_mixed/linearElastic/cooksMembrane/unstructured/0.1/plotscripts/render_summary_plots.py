#!/usr/bin/env python3
"""Render Cook membrane summary PDFs without a working gnuplot binary."""

from __future__ import annotations

import csv
import math
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.pdfgen import canvas


CASES = ["pabloMesh"]
METHODS = [
    ("jst", "JST", colors.HexColor("#4C78A8"), "square"),
    ("laplacian", "Laplacian", colors.HexColor("#5B8E55"), "circle"),
    ("rhiechow", "Rhie-Chow", colors.HexColor("#7B6AA8"), "triangle"),
    ("evenlap_m0", "Even Laplacian, m=1", colors.HexColor("#D7AAAA"), "cross"),
    ("evenlap_m1", "Even Laplacian, m=2", colors.HexColor("#B85C4B"), "cross"),
    ("evenlap_m2", "Even Laplacian, m=3", colors.HexColor("#7A2738"), "cross"),
]

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
DATA_DIR = ROOT_DIR / "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
OUT_DIR = ROOT_DIR / "plots"
YCOL = 8
REFMESH = 8
TIP_MAX_MESH_EXCLUSIVE = 7
REFERENCE_FILE = ROOT_DIR.parents[1] / "CookMembrane_summaries" / "cook1_evenlap_m2.details.tsv"
BENCHMARK_FILE = SCRIPT_DIR / "Bijelona.csv"


def read_details(path: Path) -> list[dict[str, float]]:
    rows = []
    with path.open() as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            parts = line.split()
            rows.append(
                {
                    "mesh": int(parts[0]),
                    "cells_per_side": float(parts[1]) if parts[1] != "NaN" else math.nan,
                    "execution_time": float(parts[3]),
                    "dy_scaled": float(parts[YCOL - 1]),
                }
            )
    return rows


def reference_value() -> float:
    fallback = None
    for row in read_details(REFERENCE_FILE):
        if row["mesh"] == REFMESH:
            return row["dy_scaled"]
        if row["mesh"] == 7:
            fallback = row["dy_scaled"]
    if fallback is not None:
        return fallback
    raise ValueError(f"Reference meshes {REFMESH} and 7 missing from {REFERENCE_FILE}")


def finite_bounds(values: list[float], logscale: bool = False) -> tuple[float, float]:
    clean = [value for value in values if math.isfinite(value) and (value > 0 if logscale else True)]
    lo, hi = min(clean), max(clean)
    if lo == hi:
        pad = abs(lo) * 0.1 if lo else 1.0
        return lo - pad, hi + pad
    if logscale:
        return lo / 1.35, hi * 1.35
    pad = (hi - lo) * 0.03
    return lo - pad, hi + pad


def convergence_guides(points: list[tuple[float, float]], xb: tuple[float, float]) -> tuple[float, float]:
    """Return coefficients for separated O(1/N) and O(1/N^2) guide lines."""
    clean = [(x, y) for x, y in points if x > 0 and y > 0 and math.isfinite(x) and math.isfinite(y)]
    upper_a = max(y * x for x, y in clean) * 1.45
    lower_a = min(y * x * x for x, y in clean) * 0.55

    # Keep the 2nd-order guide below the 1st-order guide across the full plot.
    max_lower_without_intersection = upper_a * xb[0] * 0.50
    lower_a = min(lower_a, max_lower_without_intersection)
    return upper_a, lower_a


class Plot:
    def __init__(self, path: Path, xlabel: str, ylabel: str, logx: bool = False, logy: bool = False):
        self.path = path
        self.xlabel = xlabel
        self.ylabel = ylabel
        self.logx = logx
        self.logy = logy
        self.width, self.height = landscape((7.0 * 72, 4.8 * 72))
        self.left, self.right, self.bottom, self.top = 58, 20, 54, 22
        self.c = canvas.Canvas(str(path), pagesize=(self.width, self.height))

    def tx(self, x: float, bounds: tuple[float, float]) -> float:
        lo, hi = bounds
        if self.logx:
            x, lo, hi = math.log10(x), math.log10(lo), math.log10(hi)
        return self.left + (x - lo) / (hi - lo) * (self.width - self.left - self.right)

    def ty(self, y: float, bounds: tuple[float, float]) -> float:
        lo, hi = bounds
        if self.logy:
            y, lo, hi = math.log10(y), math.log10(lo), math.log10(hi)
        return self.bottom + (y - lo) / (hi - lo) * (self.height - self.bottom - self.top)

    def ticks(self, bounds: tuple[float, float], logscale: bool, axis: str) -> list[float]:
        lo, hi = bounds
        if logscale:
            if axis == "x" and self.xlabel == "Cells per side":
                return [x for x in [3, 6, 12, 24, 48, 96, 192, 384] if lo <= x <= hi]
            return [
                10**p
                for p in range(math.floor(math.log10(lo)), math.ceil(math.log10(hi)) + 1)
                if lo <= 10**p <= hi
            ]
        step = 10 ** math.floor(math.log10((hi - lo) / 5))
        return [math.ceil(lo / step) * step + i * step for i in range(20) if lo <= math.ceil(lo / step) * step + i * step <= hi]

    def draw_axes(self, xb: tuple[float, float], yb: tuple[float, float]) -> None:
        c = self.c
        c.setStrokeColor(colors.HexColor("#d9d9d9"))
        c.setLineWidth(0.45)
        c.setDash(1, 2)
        xticks = self.ticks(xb, self.logx, "x")
        yticks = self.ticks(yb, self.logy, "y")
        for x in xticks:
            px = self.tx(x, xb)
            c.line(px, self.bottom, px, self.height - self.top)
        for y in yticks:
            py = self.ty(y, yb)
            c.line(self.left, py, self.width - self.right, py)
        c.setDash()

        c.setStrokeColor(colors.black)
        c.setLineWidth(1.1)
        c.rect(self.left, self.bottom, self.width - self.left - self.right, self.height - self.bottom - self.top, stroke=1, fill=0)
        c.setFont("Helvetica", 9)
        for x in xticks:
            label = (
                f"{x:g}"
                if not self.logx or self.xlabel in {"Cells per side", "Execution time [s]"}
                else f"1e{int(round(math.log10(x)))}"
            )
            c.drawCentredString(self.tx(x, xb), self.bottom - 14, label)
        for y in yticks:
            label = f"{y:.2f}" if not self.logy else f"1e{int(round(math.log10(y)))}"
            c.drawRightString(self.left - 6, self.ty(y, yb) - 3, label)

        c.setFont("Helvetica", 11)
        c.drawCentredString((self.left + self.width - self.right) / 2, 18, self.xlabel)
        c.saveState()
        c.translate(15, (self.bottom + self.height - self.top) / 2)
        c.rotate(90)
        c.drawCentredString(0, 0, self.ylabel)
        c.restoreState()

    def marker(self, x: float, y: float, colour, shape: str) -> None:
        c = self.c
        c.setStrokeColor(colour)
        c.setFillColor(colors.white)
        size = 3.2
        if shape == "circle":
            c.circle(x, y, size, stroke=1, fill=0)
        elif shape == "square":
            c.rect(x - size, y - size, 2 * size, 2 * size, stroke=1, fill=0)
        elif shape == "triangle":
            c.line(x, y + size, x - size, y - size)
            c.line(x - size, y - size, x + size, y - size)
            c.line(x + size, y - size, x, y + size)
        else:
            c.line(x - size, y - size, x + size, y + size)
            c.line(x - size, y + size, x + size, y - size)

    def draw_series(self, points: list[tuple[float, float]], xb: tuple[float, float], yb: tuple[float, float], colour, shape: str) -> None:
        if not points:
            return
        c = self.c
        c.setStrokeColor(colour)
        c.setLineWidth(1.45)
        mapped = [(self.tx(x, xb), self.ty(y, yb)) for x, y in points]
        for (x0, y0), (x1, y1) in zip(mapped, mapped[1:]):
            c.line(x0, y0, x1, y1)
        for x, y in mapped:
            self.marker(x, y, colour, shape)

    def draw_order_guides(self, xb: tuple[float, float], yb: tuple[float, float], upper_a: float, lower_a: float) -> None:
        c = self.c
        samples = [
            xb[0] * (xb[1] / xb[0]) ** (i / 80)
            for i in range(81)
        ]

        def draw_curve(values: list[tuple[float, float]], dash: tuple[int, int], label: str, label_index: int, label_scale: float) -> None:
            c.setStrokeColor(colors.black)
            c.setLineWidth(1.25)
            c.setDash(*dash)
            mapped = [(self.tx(x, xb), self.ty(y, yb)) for x, y in values]
            for (x0, y0), (x1, y1) in zip(mapped, mapped[1:]):
                c.line(x0, y0, x1, y1)
            c.setDash()
            lx, ly = values[label_index]
            c.setFillColor(colors.black)
            c.setFont("Helvetica", 8)
            c.drawString(self.tx(lx, xb) + 4, self.ty(ly * label_scale, yb), label)

        draw_curve([(x, upper_a / x) for x in samples], (7, 3), "1st order", 55, 1.07)
        draw_curve([(x, lower_a / (x * x)) for x in samples], (3, 3), "2nd order", 55, 1.18)

    def legend(self, entries=METHODS) -> None:
        c = self.c
        legend_font_size = 12
        c.setFont("Helvetica", legend_font_size)
        row_step = 17
        legend_width = max(34 + c.stringWidth(label, "Helvetica", legend_font_size) for _, label, _, _ in entries)
        x = self.width - self.right - legend_width - 10
        y = self.height - self.top - 22

        c.setFillColor(colors.white)
        c.rect(x - 5, y - row_step * (len(entries) - 1) - 5, legend_width + 10, row_step * len(entries) + 6, stroke=0, fill=1)
        for _, label, colour, shape in entries:
            c.setStrokeColor(colour)
            c.setLineWidth(1.45)
            c.line(x, y + 3, x + 16, y + 3)
            self.marker(x + 8, y + 3, colour, shape)
            c.setStrokeColor(colors.black)
            c.setFillColor(colors.black)
            c.drawString(x + 22, y, label)
            y -= row_step

    def finish(self) -> None:
        self.c.showPage()
        self.c.save()


def method_points(case: str, method: str, ykind: str, ref: float | None = None) -> list[tuple[float, float]]:
    rows = read_details(DATA_DIR / f"{case}_{method}.details.tsv")
    points = []
    for row in rows:
        if ykind == "tip" and row["mesh"] >= TIP_MAX_MESH_EXCLUSIVE:
            continue
        if ykind != "tip" and row["mesh"] >= REFMESH:
            continue
        if ykind == "tip":
            x, y = row["cells_per_side"], row["dy_scaled"]
        elif ykind == "error_cells":
            x, y = row["cells_per_side"], abs(row["dy_scaled"] - ref)
        else:
            if row["mesh"] < 2:
                continue
            x, y = row["execution_time"], abs(row["dy_scaled"] - ref)
        if math.isfinite(x) and math.isfinite(y) and x > 0 and (ykind == "tip" or y > 0):
            points.append((x, y))
    return points


def read_benchmark() -> list[tuple[float, float]]:
    points = []
    with BENCHMARK_FILE.open(newline="") as handle:
        for row in csv.reader(handle):
            if len(row) >= 2:
                points.append((float(row[1]), float(row[0])))
    return points


def draw_tip(case: str) -> None:
    series = [(method, label, colour, shape, method_points(case, method, "tip")) for method, label, colour, shape in METHODS]
    benchmark = read_benchmark()
    xs = [x for *_, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for *_, points in series for _, y in points] + [y for _, y in benchmark]
    plot = Plot(OUT_DIR / f"{case}_tipDispVsCellsPerSide.pdf", "Cells per side", "Vertical displacement")
    xb, yb = finite_bounds(xs), finite_bounds(ys)
    plot.draw_axes(xb, yb)
    plot.draw_series(benchmark, xb, yb, colors.black, "triangle")
    for _, _, colour, shape, points in series:
        plot.draw_series(points, xb, yb, colour, shape)
    plot.legend([("benchmark", "Benchmark", colors.black, "triangle"), *METHODS])
    plot.finish()


def draw_error_cells(case: str, ref: float) -> None:
    series = [(method, label, colour, shape, method_points(case, method, "error_cells", ref)) for method, label, colour, shape in METHODS]
    xs = [x for *_, points in series for x, _ in points]
    ys = [y for *_, points in series for _, y in points]
    plot = Plot(OUT_DIR / f"{case}_convergenceMethodsComparison.pdf", "Cells per side", "|d_y - d_y,ref|", logx=True, logy=True)
    xb = finite_bounds(xs, True)
    all_points = [(x, y) for *_, points in series for x, y in points]
    upper_a, lower_a = convergence_guides(all_points, xb)
    guide_values = [
        upper_a / xb[0],
        upper_a / xb[1],
        lower_a / (xb[0] * xb[0]),
        lower_a / (xb[1] * xb[1]),
    ]
    yb = finite_bounds(ys + guide_values, True)
    plot.draw_axes(xb, yb)
    for _, _, colour, shape, points in series:
        plot.draw_series(points, xb, yb, colour, shape)
    plot.draw_order_guides(xb, yb, upper_a, lower_a)
    plot.finish()


def draw_error_time(case: str, ref: float) -> None:
    series = [(method, label, colour, shape, method_points(case, method, "error_time", ref)) for method, label, colour, shape in METHODS]
    xs = [x for *_, points in series for x, _ in points]
    ys = [y for *_, points in series for _, y in points]
    plot = Plot(OUT_DIR / f"{case}_executionTimeVsTipDispError.pdf", "Execution time [s]", "|d_y - d_y,ref|", logx=True, logy=True)
    xb, yb = finite_bounds(xs, True), finite_bounds(ys, True)
    plot.draw_axes(xb, yb)
    for _, _, colour, shape, points in series:
        plot.draw_series(points, xb, yb, colour, shape)
    plot.finish()


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    ref = reference_value()
    for case in CASES:
        draw_tip(case)
        draw_error_cells(case, ref)
        draw_error_time(case, ref)
    print(f"Wrote {len(CASES) * 3} PDFs to {OUT_DIR}")


if __name__ == "__main__":
    main()
