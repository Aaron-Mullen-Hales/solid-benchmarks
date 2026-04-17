# Cook's membrane stabilisation study

This directory contains the mesh-study harness for the hex `PETScSNES` Cook's
membrane case and its pressure-stabilisation variants.

It is set up to follow the newer runtime-selectable stabilisation framework in
`s4f/src/solids4FoamModels/numerics/stabilisationModels`, not the older
`stabilisationType`/`pressureScale` path.

## Naming

Cases created by `Allrun` use:

`hex_snes__<stabilisation_tag>.<mesh_index>`

Current tags are:

- `rhiechow`
- `laplacian`
- `jst`
- `evenlap_m0`
- `evenlap_m1`

## Included checks

- `rhiechow`: pressure stabilisation type `RhieChow`
- `laplacian`: pressure stabilisation type `laplacian`
- `jst`: pressure stabilisation type `JamesonSchmidtTurkel`
- `evenlap_m0`: pressure stabilisation type `generalisedEvenOrderLaplacian`
  with `laplacianPower 0` and the same pressure coefficients as `laplacian`
  for the equivalence check
- `evenlap_m1`: pressure stabilisation type `generalisedEvenOrderLaplacian`
  with `laplacianPower 1`

The `laplacian` versus `evenlap_m0` comparison is written out separately so the
`m = 0` equivalence check is easy to inspect after each sweep.

## Mesh study

`Allrun` now defaults to meshes `1` to `3`.

For the full study, run:

`END_MESH=7 ./Allrun`

The mesh-index to cells-per-side mapping used in the post-processing is kept in
`plotscripts/meshSpacing.csv`:

- `1 -> 3`
- `2 -> 6`
- `3 -> 12`
- `4 -> 24`
- `5 -> 48`
- `6 -> 96`
- `7 -> 192`

## Bijelona comparison

The archived Bijelona reference data is copied locally into
`plotscripts/Bijelona.csv` so the comparison plots can be recreated entirely
from this case.

For comparison against Bijelona, the reported `Dy` from the case is scaled by
`0.001` before plotting. The raw `Dy` is still kept in the detailed tables.

## Outputs

Each run directory contains:

- one per-configuration summary `.summary.txt`,
- one per-configuration detail table `.details.tsv`,
- a combined `stabilisationResults.tsv`,
- an `laplacian_vs_evenlap_m0.tsv` comparison,
- plot-ready wide tables for raw `Dy` versus total cells,
- plot-ready wide tables for scaled `Dy` versus cells per side,
- plot-ready wide tables for `ClockTime`,
- plot-ready wide tables for `ExecutionTime`,
- plot-ready wide tables for maximum memory,
- plot-ready wide tables for SNES iterations,
- plot-ready wide tables for average linear iterations,
- a local copy of `Bijelona.csv` and `meshSpacing.csv`,
- PDF plots when `gnuplot` is available.

The detailed tables include:

- mesh index,
- cells per side,
- total cells,
- execution time,
- clock time,
- maximum memory,
- raw `Dy`,
- scaled `Dy`,
- SNES iterations,
- average linear iterations,
- number of linear solves,
- status and exit code.
