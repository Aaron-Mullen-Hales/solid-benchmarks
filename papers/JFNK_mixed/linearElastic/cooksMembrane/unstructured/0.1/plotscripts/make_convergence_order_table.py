#!/usr/bin/env python3
"""Create mesh-to-mesh convergence-order tables from Cook membrane summaries.

The observed order between adjacent meshes is computed from the error relative
to a reference mesh:

    p_i = log(e_i / e_{i+1}) / log(N_{i+1} / N_i),
    e_i = |d_y(N_i) - d_y(ref)|

where N is the cells-per-side value. By default, DyScaled is used and mesh 8 of
the cook100 evenlap_m2 run is the common reference, matching the plotting
scripts in this directory.
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path


CASES = ["cook001", "cook01", "cook1", "cook10", "cook100", "cook1000"]
METHODS = [
    ("evenlap_m0", "Even Laplacian, $m=0$"),
    ("evenlap_m1", "Even Laplacian, $m=1$"),
    ("evenlap_m2", "Even Laplacian, $m=2$"),
    ("jst", "JST"),
    ("laplacian", "Laplacian"),
    ("rhiechow", "Rhie--Chow"),
]


def stabilisation_coefficient(case: str) -> str:
    values = {
        "cook001": 0.01,
        "cook01": 0.1,
        "cook1": 1.0,
        "cook10": 10.0,
        "cook100": 100.0,
        "cook1000": 1000.0,
    }
    value = values[case]
    return f"{value:.3g}" if value < 1 else f"{value:.1f}"


def read_details(path: Path, ycol: int) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []
    with path.open(newline="") as handle:
        for raw in handle:
            if raw.startswith("#") or not raw.strip():
                continue
            parts = raw.split()
            mesh = int(parts[0])
            cells_per_side = float(parts[1])
            value = float(parts[ycol - 1])
            if math.isfinite(value):
                rows.append(
                    {
                        "mesh": mesh,
                        "cells_per_side": cells_per_side,
                        "value": value,
                    }
                )
    return rows


def format_order(value: float | None) -> str:
    if value is None or not math.isfinite(value):
        return "--"
    return f"{value:.2f}"


def latex_escape(text: str) -> str:
    return text.replace("_", r"\_")


def reference_value(reference_file: Path, ycol: int, refmesh: int) -> float:
    data = read_details(reference_file, ycol)
    by_mesh = {int(row["mesh"]): row for row in data}
    if refmesh not in by_mesh:
        if 7 in by_mesh:
            return float(by_mesh[7]["value"])
        raise ValueError(f"{reference_file} does not contain reference mesh {refmesh} or fallback mesh 7")
    return float(by_mesh[refmesh]["value"])


def build_rows(
    datadir: Path,
    ycol: int,
    refmesh: int,
    ref_value: float,
) -> tuple[list[str], list[dict[str, object]]]:
    table_rows: list[dict[str, object]] = []
    pair_labels: list[str] | None = None

    for case in CASES:
        coeff = stabilisation_coefficient(case)
        for method_key, method_label in METHODS:
            path = datadir / f"{case}_{method_key}.details.tsv"
            data = read_details(path, ycol)
            plotted = [row for row in data if int(row["mesh"]) < refmesh]
            plotted.sort(key=lambda row: int(row["mesh"]))

            current_labels = [
                f"{int(a['cells_per_side'])}--{int(b['cells_per_side'])}"
                for a, b in zip(plotted, plotted[1:])
            ]
            if pair_labels is None:
                pair_labels = current_labels
            elif pair_labels != current_labels:
                raise ValueError(f"{path} has mesh pairs {current_labels}, expected {pair_labels}")

            orders: list[float | None] = []
            for coarse, fine in zip(plotted, plotted[1:]):
                coarse_err = abs(float(coarse["value"]) - ref_value)
                fine_err = abs(float(fine["value"]) - ref_value)
                ratio = float(fine["cells_per_side"]) / float(coarse["cells_per_side"])
                if coarse_err <= 0 or fine_err <= 0 or ratio <= 1:
                    orders.append(None)
                else:
                    orders.append(math.log(coarse_err / fine_err) / math.log(ratio))

            table_rows.append(
                {
                    "case": case,
                    "method_key": method_key,
                    "method": method_label,
                    "coefficient": coeff,
                    "orders": orders,
                }
            )

    return pair_labels or [], table_rows


def write_tsv(path: Path, pair_labels: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["stab_method", "stab_coeff", *[f"p_{label}" for label in pair_labels]])
        for row in rows:
            writer.writerow(
                [
                    row["method_key"],
                    row["coefficient"],
                    *[format_order(order) for order in row["orders"]],
                ]
            )


def write_latex(path: Path, pair_labels: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    alignment = "ll" + "c" * len(pair_labels)
    header = (
        r"Stab. method & Stab. coeff. & "
        + " & ".join(rf"$p_{{{label}}}$" for label in pair_labels)
        + r" \\"
    )

    lines = [
        rf"\begin{{tabular}}{{{alignment}}}",
        r"\toprule",
        header,
        r"\midrule",
    ]

    previous_coeff = None
    for row in rows:
        coeff = str(row["coefficient"])
        if previous_coeff is not None and coeff != previous_coeff:
            lines.append(r"\addlinespace")
        previous_coeff = coeff
        orders = " & ".join(format_order(order) for order in row["orders"])
        lines.append(f"{row['method']} & {coeff} & {orders} " + r"\\")

    lines.extend(
        [
            r"\bottomrule",
            r"\end{tabular}",
            "",
        ]
    )
    path.write_text("\n".join(lines))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create TSV and LaTeX tables of observed mesh-to-mesh convergence orders."
    )
    parser.add_argument("--datadir", default=".", type=Path, help="Directory containing *.details.tsv files.")
    parser.add_argument("--refmesh", default=8, type=int, help="Reference mesh index.")
    parser.add_argument(
        "--reference-file",
        default=None,
        type=Path,
        help="Details TSV containing the common reference solution.",
    )
    parser.add_argument("--ycol", default=8, type=int, help="1-based column index for displacement values.")
    parser.add_argument(
        "--tsv",
        default=Path("tables/convergence_orders.tsv"),
        type=Path,
        help="Output TSV path.",
    )
    parser.add_argument(
        "--tex",
        default=Path("tables/convergence_orders.tex"),
        type=Path,
        help="Output LaTeX table path.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    reference_file = args.reference_file or (args.datadir / "cook1_evenlap_m2.details.tsv")
    ref_value = reference_value(reference_file, args.ycol, args.refmesh)
    pair_labels, rows = build_rows(args.datadir, args.ycol, args.refmesh, ref_value)
    write_tsv(args.tsv, pair_labels, rows)
    write_latex(args.tex, pair_labels, rows)
    print(f"Reference: {reference_file}, mesh {args.refmesh}, value {ref_value:g}")
    print(f"Wrote {args.tsv}")
    print(f"Wrote {args.tex}")


if __name__ == "__main__":
    main()
