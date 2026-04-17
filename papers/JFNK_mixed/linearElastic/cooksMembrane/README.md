# Cook's membrane stabilisation tests

This directory is a contained harness for pressure-stabilisation checks on the
hex `PETScSNES` Cook's membrane case.

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
  with `laplacianPower 0`
- `evenlap_m1`: pressure stabilisation type `generalisedEvenOrderLaplacian`
  with `laplacianPower 1`

The `laplacian` versus `evenlap_m0` comparison is written out separately so the
`m = 0` equivalence check is easy to inspect after each sweep.

## Outputs

Each run directory contains:

- one per-configuration summary `.summary.txt`,
- one per-configuration detail table `.details.tsv`,
- a combined `stabilisationResults.tsv`,
- an `laplacian_vs_evenlap_m0.tsv` comparison,
- plot-ready wide tables for displacement, time, and memory,
- PDF plots when `gnuplot` is available.
