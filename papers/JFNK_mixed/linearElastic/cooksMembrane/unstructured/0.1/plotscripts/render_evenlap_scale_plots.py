#!/usr/bin/env python3
"""Render even-Laplacian scale comparison plots for MomStab summaries."""

from __future__ import annotations

import csv
import math
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.pdfgen import canvas


DATA_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = DATA_DIR / "plots"
YCOL = 8
REFMESH = 7

SCALES = [
    ("cook001", "0.01", ["#dadaeb", "#9e9ac8", "#54278f"]),
    ("cook01", "0.1", ["#bdd7e7", "#6baed6", "#08519c"]),
    ("cook1", "1", ["#c7eae5", "#5ab4ac", "#01665e"]),
    ("cook10", "10", ["#c7e9c0", "#74c476", "#006d2c"]),
    ("cook100", "100", ["#fdd0a2", "#fd8d3c", "#d94801"]),
    ("cook1000", "1000", ["#fcbba1", "#fb6a4a", "#a50f15"]),
]
METHODS = [("evenlap_m0", "m=0", 0), ("evenlap_m1", "m=1", 1), ("evenlap_m2", "m=2", 2)]


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
                    "value": float(parts[YCOL - 1]),
                }
            )
    return rows


def read_benchmark() -> list[tuple[float, float]]:
    points = []
    with (DATA_DIR / "Bijelona.csv").open(newline="") as handle:
        for row in csv.reader(handle):
            if len(row) >= 2:
                points.append((float(row[1]), float(row[0])))
    return points


def data_points(case: str, method: str) -> list[tuple[float, float]]:
    points = []
    for row in read_details(DATA_DIR / f"{case}_{method}.details.tsv"):
        if row["mesh"] < REFMESH and math.isfinite(row["cells_per_side"]) and math.isfinite(row["value"]):
            points.append((row["cells_per_side"], row["value"]))
    return points


def bounds(values: list[float]) -> tuple[float, float]:
    lo, hi = min(values), max(values)
    if lo == hi:
        return lo - 1, hi + 1
    pad = (hi - lo) * 0.08
    return lo - pad, hi + pad


class Plot:
    def __init__(self, path: Path):
        self.width, self.height = landscape((7.0 * 72, 4.8 * 72))
        self.left, self.right, self.bottom, self.top = 58, 20, 54, 86
        self.c = canvas.Canvas(str(path), pagesize=(self.width, self.height))

    def tx(self, x: float, xb: tuple[float, float]) -> float:
        return self.left + (x - xb[0]) / (xb[1] - xb[0]) * (self.width - self.left - self.right)

    def ty(self, y: float, yb: tuple[float, float]) -> float:
        return self.bottom + (y - yb[0]) / (yb[1] - yb[0]) * (self.height - self.bottom - self.top)

    def draw_axes(self, xb: tuple[float, float], yb: tuple[float, float]) -> None:
        c = self.c
        c.setStrokeColor(colors.HexColor("#dddddd"))
        c.setLineWidth(0.5)
        xticks = [3, 6, 12, 24, 48, 96, 192, 384]
        for x in xticks:
            if xb[0] <= x <= xb[1]:
                px = self.tx(x, xb)
                c.line(px, self.bottom, px, self.height - self.top)
        step = 10 ** math.floor(math.log10((yb[1] - yb[0]) / 5))
        yticks = [math.ceil(yb[0] / step) * step + i * step for i in range(20)]
        for y in yticks:
            if yb[0] <= y <= yb[1]:
                py = self.ty(y, yb)
                c.line(self.left, py, self.width - self.right, py)

        c.setStrokeColor(colors.black)
        c.setLineWidth(1.1)
        c.rect(self.left, self.bottom, self.width - self.left - self.right, self.height - self.bottom - self.top, stroke=1, fill=0)
        c.setFont("Helvetica", 9)
        for x in xticks:
            if xb[0] <= x <= xb[1]:
                c.drawCentredString(self.tx(x, xb), self.bottom - 14, f"{x:g}")
        for y in yticks:
            if yb[0] <= y <= yb[1]:
                c.drawRightString(self.left - 6, self.ty(y, yb) - 3, f"{y:.2f}")

        c.setFont("Helvetica", 11)
        c.drawCentredString((self.left + self.width - self.right) / 2, 18, "Cells per side")
        c.saveState()
        c.translate(15, (self.bottom + self.height - self.top) / 2)
        c.rotate(90)
        c.drawCentredString(0, 0, "Vertical displacement")
        c.restoreState()

    def marker(self, x: float, y: float, colour) -> None:
        c = self.c
        c.setStrokeColor(colour)
        size = 4
        c.line(x - size, y - size, x + size, y + size)
        c.line(x - size, y + size, x + size, y - size)

    def draw_series(self, points: list[tuple[float, float]], xb: tuple[float, float], yb: tuple[float, float], colour, dashed: bool = False) -> None:
        if not points:
            return
        c = self.c
        c.setStrokeColor(colour)
        c.setLineWidth(2.0 if not dashed else 2.4)
        if dashed:
            c.setDash(6, 4)
        mapped = [(self.tx(x, xb), self.ty(y, yb)) for x, y in points]
        for (x0, y0), (x1, y1) in zip(mapped, mapped[1:]):
            c.line(x0, y0, x1, y1)
        c.setDash()
        for x, y in mapped:
            if dashed:
                c.line(x - 4, y - 4, x + 4, y + 4)
                c.line(x - 4, y + 4, x + 4, y - 4)
            else:
                self.marker(x, y, colour)

    def legend(self, entries: list[tuple[str, object]], row_limit: int = 4) -> None:
        c = self.c
        c.setFont("Helvetica", 8)
        max_width = self.width - self.left - self.right
        rows: list[list[tuple[str, object, float]]] = [[]]
        for label, colour in entries:
            entry_width = 34 + c.stringWidth(label, "Helvetica", 8)
            if rows[-1] and (sum(item[2] for item in rows[-1]) + entry_width > max_width or len(rows[-1]) >= row_limit):
                rows.append([])
            rows[-1].append((label, colour, entry_width))

        y = self.height - 22
        for row in rows:
            x = self.left + (max_width - sum(item[2] for item in row)) / 2
            for label, colour, entry_width in row:
                c.setStrokeColor(colour)
                c.setLineWidth(2.0)
                if label == "Benchmark":
                    c.setDash(6, 4)
                c.line(x, y + 3, x + 16, y + 3)
                c.setDash()
                self.marker(x + 8, y + 3, colour)
                c.setFillColor(colors.black)
                c.drawString(x + 22, y, label)
                x += entry_width
            y -= 13

    def finish(self) -> None:
        self.c.showPage()
        self.c.save()


def render(path: Path, series: list[tuple[str, list[tuple[float, float]], object]], row_limit: int = 4) -> None:
    benchmark = read_benchmark()
    xs = [x for _, points, _ in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for _, points, _ in series for _, y in points] + [y for _, y in benchmark]
    plot = Plot(path)
    xb, yb = bounds(xs), bounds(ys)
    plot.draw_axes(xb, yb)
    plot.draw_series(benchmark, xb, yb, colors.HexColor("#111111"), dashed=True)
    for _, points, colour in series:
        plot.draw_series(points, xb, yb, colour)
    plot.legend([("Benchmark", colors.HexColor("#111111")), *[(label, colour) for label, _, colour in series]], row_limit=row_limit)
    plot.finish()


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)

    all_series = []
    for case, scale, palette in SCALES:
        for method, method_label, shade in METHODS:
            all_series.append((f"{scale}, {method_label}", data_points(case, method), colors.HexColor(palette[shade])))
    render(OUT_DIR / "evenlap_scales_all_tipDispVsCellsPerSide.pdf", all_series, row_limit=4)

    scale_colours = {
        "0.01": "#54278f",
        "0.1": "#08519c",
        "1": "#01665e",
        "10": "#006d2c",
        "100": "#d94801",
        "1000": "#a50f15",
    }
    for method, method_label, _ in METHODS:
        series = [
            (scale, data_points(case, method), colors.HexColor(scale_colours[scale]))
            for case, scale, _ in SCALES
        ]
        render(OUT_DIR / f"evenlap_scales_{method_label.replace('=', '')}_tipDispVsCellsPerSide.pdf", series, row_limit=7)

    print(f"Wrote 4 PDFs to {OUT_DIR}")


if __name__ == "__main__":
    main()
