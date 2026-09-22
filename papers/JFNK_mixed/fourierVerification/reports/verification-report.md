# Raw Fourier verification report

Implemented on branch `verify-raw-pressure-fourier` from committed baseline `fcf057aa0f3f55b16290abee5ce8b159c366f5f8`.
The worktree is
`/Volumes/OpenFoam/aaronmullen-hales-v2312/run/paper1Code/papers/JFNK_mixed/fourierVerification/raw-operators`.
The original `fix-pressure-solid` checkout still
contains its separate 13-file spectral-normalisation changes; this worktree
does not include them. No commits or staging were performed.

## Outcome

All 168 primary operator/mode checks passed on OpenFOAM.com v2312,
Clang, double precision, serial execution. Each of seven production model
configurations was tested on eight modes at measured resolutions 16x16x1,
32x32x1 and 64x64x1. All 72 equivalent-pair field checks and 168 gamma checks
passed. Pair-field differences were exactly zero. Null-gamma and unit-gamma
results were bitwise identical. Independent literal golden values and
measured spacing ratios passed in a fresh regression copy and check-only run.

The worst relative eigenvalue error was `5.6011e-14`. The worst relative
eigenmode residual was `4.1561e-11`. The worst reference-scaled eigenmode
residual was `5.7682e-15`. The tolerance was `1e-9`.

An additional anisotropic case, hx=1/16 and hy=1/8, passed all 56
operator/mode checks using the anisotropic analytical formulas.

## Scope and findings

The numerical path uses `stabilisationModel::New`, production
`updateScalar(p, &gradP)` and `cellScalar(&rAUf, true)`. No stabilisation
algorithm, solid solver, spectral-normalisation setting or higher-order
split family was changed or added. RhieChow uses existing inheritance.
The analytical function contains mathematical formulas and no copied stencil.

The current Laplacian/gen0 symbol has no numerical `1/h^2` factor;
JST/gen1/gen2/diffStencil/RhieChow do. Measured ratios at fixed angles were
1 for Laplacian/gen0 and 4 for every other model when N doubled.
This confirms the current implementation. Whether the special gen0 branch
agrees with an intended paper formula remains unresolved: no authoritative
paper formula was supplied or found in the local JFNK mixed case material.
The test preserves current behaviour without deciding whether it is a bug.

The diffStencil/RhieChow symbol depends on `grad(p) Gauss linear`, linear
face interpolation and uncorrected normal gradients. Their constant-mode
Rayleigh values can be tiny nonzero roundoff (about 1e-31), while their
reference-scaled residual is about 1e-17. Constants are tested with the
reference-scaled tolerance; their undefined relative errors are blank.

An initial runner based on ordinary `foamDictionary -set nCells` silently
expanded `$nCells`, so all nominal resolutions stayed at 16. Coverage checks
caught this before completion. `Allrun` now preserves macros with
`-disableFunctionEntries` and restores the original file exactly. The final
results tables below come from measured distinct meshes in the corrected
fresh regression run.

## Build commands

These commands were used in Bash at the worktree root. They isolate the
rebuilt production libraries from the older shared user library:

```bash
source /Volumes/OpenFoam/OpenFOAM-v2312/etc/bashrc
export FOAM_MODULE_PREFIX="$PWD/.build/raw"
export EIGEN_DIR=/opt/homebrew/include/eigen3
export WM_NCOMPPROCS=8
unset PETSC_DIR PETSC_ARCH
mkdir -p "$FOAM_MODULE_PREFIX/lib" "$FOAM_MODULE_PREFIX/bin"
./ThirdParty/Allwmake > .build/thirdParty.log 2>&1
./src/Allwmake -j 8 > .build/build-src.log 2>&1
wmake applications/utilities/stabilisationFourierCheck \
  > .build/build-utility.log 2>&1
```

All three production libraries were rebuilt. The dynamic loader trace at
`.build/library-provenance.log` confirms loading `libsolids4FoamModels`,
`libblockCoupledSolids4FoamTools` and `libRBFMeshMotionSolver` from
`.build/raw/lib`. Source and utility builds had no errors; existing
production headers emit warnings. `src/Allwmake` has existing pipelines
which can hide a sub-build status, so its complete log was checked for errors.

## Run commands

From the worktree root after loading OpenFOAM:

```bash
export PATH="$PWD/.build/raw/bin:$PWD/applications/scripts:/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export DYLD_LIBRARY_PATH="$PWD/.build/raw/lib:$FOAM_LIBBIN:$FOAM_LIBBIN/$FOAM_MPI:$FOAM_EXT_LIBBIN:${DYLD_LIBRARY_PATH:-}"
cd tutorials/solids/verification/pressureStabilisationFourier
./Allrun > log.Allrun 2>&1
python3 checkResults.py
./regressionTest.sh > log.regressionTest 2>&1
./regressionTest.sh --check-only
```

Plot command used from the worktree root (this Python has matplotlib/numpy):

```bash
MPLCONFIGDIR="$PWD/.build/matplotlib" XDG_CACHE_HOME="$PWD/.build/cache" \
  /opt/miniconda3/bin/python \
  tutorials/solids/verification/pressureStabilisationFourier/plotSymbols.py \
  tutorials/solids/verification/pressureStabilisationFourier/postProcessing/stabilisationFourierCheck
```

Generated plots were visually inspected. The plot script reads exported
symbols and measured values without implementing analytical formulas.

## Failure and additional validation

- Tolerance `1e-20`: utility returned exit code 1, reported 51 failed checks
  and wrote the complete 56-row result CSV first.
- Incompatible theta/pi `(0.1,0,0)` on the 64 mesh: rejected, exit code 1.
- Nonuniform Cartesian mesh (grading 1.3): rejected, exit code 1.
- Anisotropic uniform mesh: exit code 0, 56/56 operator/mode checks passed.
- `-writeFields`: all 14 uniquely named pressure/stabilisation fields for
  a checkerboard mode were written; repeating the run gave identical CSVs.
  No file named `faceStabilisation(p)` was written.
- Bash syntax, Python compilation, Markdown lint on both changed documents,
  and whitespace/diff checks passed.
- Repository-wide README/regression-presence scripts find existing missing
  files in unrelated tutorials. They also scan generated regression copies;
  the new source case contains both required files. These unrelated checks
  were not fixed in this task.

OpenFOAM.org and foam-extend builds were not available and were not tested.
The utility uses compatibility accessors and portable integer counts;
foam-extend case execution is explicitly skipped. No solid-mechanics
solver was run because this utility tests only the operator classes.

## Files created

- `applications/utilities/stabilisationFourierCheck/Make/files`
- `applications/utilities/stabilisationFourierCheck/Make/options`
- `applications/utilities/stabilisationFourierCheck/cartesianMeshInfo.H`
- `applications/utilities/stabilisationFourierCheck/fourierSymbols.H`
- `applications/utilities/stabilisationFourierCheck/stabilisationFourierCheck.C`
- `applications/utilities/stabilisationFourierCheck/stabilisationFourierCheckDict`
- `tutorials/solids/verification/pressureStabilisationFourier/.gitignore`
- `tutorials/solids/verification/pressureStabilisationFourier/0/.gitkeep`
- `tutorials/solids/verification/pressureStabilisationFourier/Allclean`
- `tutorials/solids/verification/pressureStabilisationFourier/Allrun`
- `tutorials/solids/verification/pressureStabilisationFourier/README.md`
- `tutorials/solids/verification/pressureStabilisationFourier/checkResults.py`
- `tutorials/solids/verification/pressureStabilisationFourier/constant/.gitkeep`
- `tutorials/solids/verification/pressureStabilisationFourier/plotSymbols.py`
- `tutorials/solids/verification/pressureStabilisationFourier/regressionTest.sh`
- `tutorials/solids/verification/pressureStabilisationFourier/system/blockMeshDict`
- `tutorials/solids/verification/pressureStabilisationFourier/system/controlDict`
- `tutorials/solids/verification/pressureStabilisationFourier/system/fvSchemes`
- `tutorials/solids/verification/pressureStabilisationFourier/system/fvSolution`
- `tutorials/solids/verification/pressureStabilisationFourier/system/stabilisationFourierDict`

## Files modified

- `applications/utilities/README.md`
- `tutorials/Alltest-regression`

`applications/Allwmake` already discovers utility directories, so no build
registration change was needed. `tutorials/Alltest-regression` now includes
the new case. No source files under `src/` or `applications/solvers/` differ
from the committed baseline.

## Machine-readable results and plots

Primary CSVs and plots are in
`tutorials/solids/verification/pressureStabilisationFourier/postProcessing/stabilisationFourierCheck`.
The independent fresh regression run writes the corresponding CSVs under
`regressionTests/main/postProcessing/stabilisationFourierCheck` in the same
case. Each resolution has results, cross-checks, gamma checks and exported
analytical cuts/maps. Generated data and logs are ignored by git.
Additional-validation evidence is below `.build/anisotropicCheck`,
`.build/nonuniformCheck`, `.build/toleranceFailure`, `.build/invalidMode`
and `.build/writeFieldsCheck`.

## Future analytical extension

The exact extension point is `expectedEigenvalue()` at
`applications/utilities/stabilisationFourierCheck/fourierSymbols.H:34`.
Its comment at line 47 marks where normalisation belongs. It receives the
model dictionary verbatim, theta, spacings and mesh counts. Later refactor
its raw branches into a raw-symbol value and apply the normalised formula
at the common return point; no such formula or dictionary setting exists
in this change. Production numerical evaluation at
`stabilisationFourierCheck.C:282` remains independent.

## Diff summary

The complete reviewable patch is `raw-fourier-verification.patch` alongside
this report; it includes tracked modifications and currently untracked
new files without staging or committing.

```text
 applications/utilities/README.md                   |   14 +
 tutorials/Alltest-regression                       |    1
 .../utilities/stabilisationFourierCheck/Make/files |    3
 .../stabilisationFourierCheck/Make/options         |   16 +
 .../stabilisationFourierCheck/cartesianMeshInfo.H  |  177 ++++++++
 .../stabilisationFourierCheck/fourierSymbols.H     |  109 +++++
 .../stabilisationFourierCheck.C                    |  421 ++++++++++++++++++++
 .../stabilisationFourierCheckDict                  |   40 ++
 .../pressureStabilisationFourier/.gitignore        |    5
 .../pressureStabilisationFourier/0/.gitkeep        |    0
 .../pressureStabilisationFourier/Allclean          |   12 +
 .../pressureStabilisationFourier/Allrun            |   20 +
 .../pressureStabilisationFourier/README.md         |  134 ++++++
 .../pressureStabilisationFourier/checkResults.py   |  106 +++++
 .../pressureStabilisationFourier/constant/.gitkeep |    0
 .../pressureStabilisationFourier/plotSymbols.py    |   98 +++++
 .../pressureStabilisationFourier/regressionTest.sh |   36 ++
 .../system/blockMeshDict                           |   29 +
 .../system/controlDict                             |   19 +
 .../pressureStabilisationFourier/system/fvSchemes  |   18 +
 .../pressureStabilisationFourier/system/fvSolution |    9
 .../system/stabilisationFourierDict                |   40 ++
 22 files changed, 1307 insertions(+)
```

<!-- markdownlint-disable MD013 -->

## Results for every primary operator/mode

Angles are theta/pi; integer mode indices are included in the CSVs.
`rel lambda` is relative to the mode's own nonzero exact eigenvalue;
`E` is the requested relative eigenmode residual. `E_ref` uses the
checkerboard response and covers the constant mode. Each row lists the
production runtime type and generalised power when applicable.

### 16x16x1

| Model (power) | theta/pi (x,y) | lambda_exact | lambda_num | rel lambda | E | E_ref | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| laplacian | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| laplacian | (0.5, 0) | -0.74 | -0.74 | 1.05021096924e-15 | 2.47587669821e-15 | 6.18969174553e-16 | PASS |
| laplacian | (1, 0) | -1.48 | -1.48 | 2.10042193848e-15 | 1.06822419975e-15 | 5.34112099876e-16 | PASS |
| laplacian | (0.5, 0.5) | -1.48 | -1.48 | 1.2002411077e-15 | 2.08551288991e-15 | 1.04275644495e-15 | PASS |
| laplacian | (1, 0.5) | -2.22 | -2.22 | 4.20084387696e-15 | 1.58893116344e-15 | 1.19169837258e-15 | PASS |
| laplacian | (0.5, 1) | -2.22 | -2.22 | 4.00080369234e-15 | 1.60272337045e-15 | 1.20204252784e-15 | PASS |
| laplacian | (1, 1) | -2.96 | -2.96 | 1.95039180002e-15 | 7.83573154412e-16 | 7.83573154412e-16 | PASS |
| laplacian | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 2.71006533712e-15 | 9.7150198911e-15 | 1.84877963943e-16 | PASS |
| JamesonSchmidtTurkel | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| JamesonSchmidtTurkel | (0.5, 0) | -378.88 | -378.88 | 1.35027124617e-15 | 5.20687421107e-15 | 3.25429638192e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0) | -1515.52 | -1515.52 | 1.95039180002e-15 | 1.44774953842e-15 | 3.61937384605e-16 | PASS |
| JamesonSchmidtTurkel | (0.5, 0.5) | -1515.52 | -1515.52 | 1.80036166155e-15 | 3.2337650606e-15 | 8.08441265149e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0.5) | -3409.92 | -3409.92 | 1.33360123078e-16 | 2.01246974947e-15 | 1.13201423408e-15 | PASS |
| JamesonSchmidtTurkel | (0.5, 1) | -3409.92 | -3409.92 | 4.00080369234e-16 | 1.97944262946e-15 | 1.11343647907e-15 | PASS |
| JamesonSchmidtTurkel | (1, 1) | -6062.08 | -6062.08 | 1.95039180002e-15 | 9.65819016355e-16 | 9.65819016355e-16 | PASS |
| JamesonSchmidtTurkel | (0.125, 0) | -2.19535407223 | -2.19535407223 | 2.22514507803e-15 | 3.02855247678e-13 | 1.09677619115e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0) | -0.74 | -0.74 | 1.05021096924e-15 | 2.47587669821e-15 | 6.18969174553e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0) | -1.48 | -1.48 | 2.10042193848e-15 | 1.06822419975e-15 | 5.34112099876e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0.5) | -1.48 | -1.48 | 1.2002411077e-15 | 2.08551288991e-15 | 1.04275644495e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0.5) | -2.22 | -2.22 | 4.20084387696e-15 | 1.58893116344e-15 | 1.19169837258e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 1) | -2.22 | -2.22 | 4.00080369234e-15 | 1.60272337045e-15 | 1.20204252784e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 1) | -2.96 | -2.96 | 1.95039180002e-15 | 7.83573154412e-16 | 7.83573154412e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 2.71006533712e-15 | 9.7150198911e-15 | 1.84877963943e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0) | -378.88 | -378.88 | 1.35027124617e-15 | 5.20687421107e-15 | 3.25429638192e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0) | -1515.52 | -1515.52 | 1.95039180002e-15 | 1.44774953842e-15 | 3.61937384605e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0.5) | -1515.52 | -1515.52 | 1.80036166155e-15 | 3.2337650606e-15 | 8.08441265149e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0.5) | -3409.92 | -3409.92 | 1.33360123078e-16 | 2.01246974947e-15 | 1.13201423408e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 1) | -3409.92 | -3409.92 | 4.00080369234e-16 | 1.97944262946e-15 | 1.11343647907e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 1) | -6062.08 | -6062.08 | 1.95039180002e-15 | 9.65819016355e-16 | 9.65819016355e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.125, 0) | -2.19535407223 | -2.19535407223 | 2.22514507803e-15 | 3.02855247678e-13 | 1.09677619115e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0) | -757.76 | -757.76 | 2.85057263079e-15 | 2.12587918282e-14 | 3.32168622315e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0) | -6062.08 | -6062.08 | 2.85057263079e-15 | 2.77119832241e-15 | 3.46399790301e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0.5) | -6062.08 | -6062.08 | 3.15063290772e-15 | 6.73047894402e-15 | 8.41309868003e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0.5) | -20459.52 | -20459.52 | 5.33440492312e-16 | 2.70975512894e-15 | 1.14317794502e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 1) | -20459.52 | -20459.52 | 5.33440492312e-16 | 2.82028016901e-15 | 1.1898056963e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 1) | -48496.64 | -48496.64 | 1.95039180002e-15 | 1.54086480537e-15 | 1.54086480537e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.125, 0) | -0.334222756562 | -0.334222756562 | 1.99308336041e-15 | 1.26236627606e-11 | 8.69980964817e-17 | PASS |
| diffStencilLaplacian | (0, 0) | -0 | 4.62223186653e-31 | n/a | n/a | 2.25998295443e-17 | PASS |
| diffStencilLaplacian | (0.5, 0) | -94.72 | -94.72 | 1.2002411077e-15 | 5.28537377818e-15 | 6.60671722272e-16 | PASS |
| diffStencilLaplacian | (1, 0) | -378.88 | -378.88 | 2.40048221541e-15 | 1.64721182618e-15 | 8.23605913089e-16 | PASS |
| diffStencilLaplacian | (0.5, 0.5) | -189.44 | -189.44 | 1.95039180002e-15 | 4.22356879898e-15 | 1.05589219975e-15 | PASS |
| diffStencilLaplacian | (1, 0.5) | -473.6 | -473.6 | 9.60192886162e-16 | 2.15606240845e-15 | 1.34753900528e-15 | PASS |
| diffStencilLaplacian | (0.5, 1) | -473.6 | -473.6 | 6.00120553851e-16 | 2.0413179058e-15 | 1.27582369112e-15 | PASS |
| diffStencilLaplacian | (1, 1) | -757.76 | -757.76 | 2.10042193848e-15 | 1.17057163769e-15 | 1.17057163769e-15 | PASS |
| diffStencilLaplacian | (0.125, 0) | -0.548838518057 | -0.548838518057 | 8.69829439594e-15 | 2.23221471288e-13 | 1.61677234877e-16 | PASS |
| RhieChow | (0, 0) | -0 | 4.62223186653e-31 | n/a | n/a | 2.25998295443e-17 | PASS |
| RhieChow | (0.5, 0) | -94.72 | -94.72 | 1.2002411077e-15 | 5.28537377818e-15 | 6.60671722272e-16 | PASS |
| RhieChow | (1, 0) | -378.88 | -378.88 | 2.40048221541e-15 | 1.64721182618e-15 | 8.23605913089e-16 | PASS |
| RhieChow | (0.5, 0.5) | -189.44 | -189.44 | 1.95039180002e-15 | 4.22356879898e-15 | 1.05589219975e-15 | PASS |
| RhieChow | (1, 0.5) | -473.6 | -473.6 | 9.60192886162e-16 | 2.15606240845e-15 | 1.34753900528e-15 | PASS |
| RhieChow | (0.5, 1) | -473.6 | -473.6 | 6.00120553851e-16 | 2.0413179058e-15 | 1.27582369112e-15 | PASS |
| RhieChow | (1, 1) | -757.76 | -757.76 | 2.10042193848e-15 | 1.17057163769e-15 | 1.17057163769e-15 | PASS |
| RhieChow | (0.125, 0) | -0.548838518057 | -0.548838518057 | 8.69829439594e-15 | 2.23221471288e-13 | 1.61677234877e-16 | PASS |

### 32x32x1

| Model (power) | theta/pi (x,y) | lambda_exact | lambda_num | rel lambda | E | E_ref | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| laplacian | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| laplacian | (0.5, 0) | -0.74 | -0.74 | 7.80156720007e-15 | 3.85484309852e-15 | 9.63710774631e-16 | PASS |
| laplacian | (1, 0) | -1.48 | -1.48 | 3.45069318465e-15 | 1.88607687665e-15 | 9.43038438326e-16 | PASS |
| laplacian | (0.5, 0.5) | -1.48 | -1.48 | 7.95159733853e-15 | 3.17178673281e-15 | 1.58589336641e-15 | PASS |
| laplacian | (1, 0.5) | -2.22 | -2.22 | 1.78035764309e-14 | 2.69488949753e-15 | 2.02116712314e-15 | PASS |
| laplacian | (0.5, 1) | -2.22 | -2.22 | 1.82036568002e-14 | 2.7141294916e-15 | 2.0355971187e-15 | PASS |
| laplacian | (1, 1) | -2.96 | -2.96 | 3.90078360003e-15 | 1.46264357172e-15 | 1.46264357172e-15 | PASS |
| laplacian | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 5.78968503839e-15 | 1.61884415537e-14 | 3.08067934746e-16 | PASS |
| JamesonSchmidtTurkel | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| JamesonSchmidtTurkel | (0.5, 0) | -1515.52 | -1515.52 | 1.05021096924e-14 | 8.88218040758e-15 | 5.55136275474e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0) | -6062.08 | -6062.08 | 3.45069318465e-15 | 2.82740254034e-15 | 7.06850635086e-16 | PASS |
| JamesonSchmidtTurkel | (0.5, 0.5) | -6062.08 | -6062.08 | 1.05021096924e-14 | 5.11216962258e-15 | 1.27804240565e-15 | PASS |
| JamesonSchmidtTurkel | (1, 0.5) | -13639.68 | -13639.68 | 1.25358515693e-14 | 3.71924811779e-15 | 2.09207706626e-15 | PASS |
| JamesonSchmidtTurkel | (0.5, 1) | -13639.68 | -13639.68 | 1.28025718155e-14 | 3.32806242435e-15 | 1.8720351137e-15 | PASS |
| JamesonSchmidtTurkel | (1, 1) | -24248.32 | -24248.32 | 4.35087401542e-15 | 1.73306271917e-15 | 1.73306271917e-15 | PASS |
| JamesonSchmidtTurkel | (0.125, 0) | -8.78141628891 | -8.78141628891 | 1.01142958092e-15 | 5.42869397256e-13 | 1.96597626879e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0) | -0.74 | -0.74 | 7.80156720007e-15 | 3.85484309852e-15 | 9.63710774631e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0) | -1.48 | -1.48 | 3.45069318465e-15 | 1.88607687665e-15 | 9.43038438326e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0.5) | -1.48 | -1.48 | 7.95159733853e-15 | 3.17178673281e-15 | 1.58589336641e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0.5) | -2.22 | -2.22 | 1.78035764309e-14 | 2.69488949753e-15 | 2.02116712314e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 1) | -2.22 | -2.22 | 1.82036568002e-14 | 2.7141294916e-15 | 2.0355971187e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 1) | -2.96 | -2.96 | 3.90078360003e-15 | 1.46264357172e-15 | 1.46264357172e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 5.78968503839e-15 | 1.61884415537e-14 | 3.08067934746e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0) | -1515.52 | -1515.52 | 1.05021096924e-14 | 8.88218040758e-15 | 5.55136275474e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0) | -6062.08 | -6062.08 | 3.45069318465e-15 | 2.82740254034e-15 | 7.06850635086e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0.5) | -6062.08 | -6062.08 | 1.05021096924e-14 | 5.11216962258e-15 | 1.27804240565e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0.5) | -13639.68 | -13639.68 | 1.25358515693e-14 | 3.71924811779e-15 | 2.09207706626e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 1) | -13639.68 | -13639.68 | 1.28025718155e-14 | 3.32806242435e-15 | 1.8720351137e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 1) | -24248.32 | -24248.32 | 4.35087401542e-15 | 1.73306271917e-15 | 1.73306271917e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.125, 0) | -8.78141628891 | -8.78141628891 | 1.01142958092e-15 | 5.42869397256e-13 | 1.96597626879e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0) | -3031.04 | -3031.04 | 1.0052019277e-14 | 3.72190509466e-14 | 5.81547671041e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0) | -24248.32 | -24248.32 | 1.65033152309e-15 | 5.26898056295e-15 | 6.58622570369e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0.5) | -24248.32 | -24248.32 | 1.2002411077e-14 | 1.02166308492e-14 | 1.27707885615e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0.5) | -81838.08 | -81838.08 | 1.95594847181e-15 | 5.29494163487e-15 | 2.23380350221e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 1) | -81838.08 | -81838.08 | 1.06688098462e-15 | 4.52573287202e-15 | 1.90929355539e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 1) | -193986.56 | -193986.56 | 3.45069318465e-15 | 2.72500128229e-15 | 2.72500128229e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.125, 0) | -1.33689102625 | -1.33689102625 | 1.16263196024e-15 | 2.28771420578e-11 | 1.57661674723e-16 | PASS |
| diffStencilLaplacian | (0, 0) | -0 | -6.93334779979e-32 | n/a | n/a | 2.16501356206e-17 | PASS |
| diffStencilLaplacian | (0.5, 0) | -378.88 | -378.88 | 8.85177816931e-15 | 9.49619799914e-15 | 1.18702474989e-15 | PASS |
| diffStencilLaplacian | (1, 0) | -1515.52 | -1515.52 | 3.15063290772e-15 | 2.86770567003e-15 | 1.43385283502e-15 | PASS |
| diffStencilLaplacian | (0.5, 0.5) | -757.76 | -757.76 | 1.06521398309e-14 | 7.36249110145e-15 | 1.84062277536e-15 | PASS |
| diffStencilLaplacian | (1, 0.5) | -1894.4 | -1894.4 | 1.80036166155e-15 | 3.94134469022e-15 | 2.46334043139e-15 | PASS |
| diffStencilLaplacian | (0.5, 1) | -1894.4 | -1894.4 | 1.92038577232e-15 | 4.03979461751e-15 | 2.52487163594e-15 | PASS |
| diffStencilLaplacian | (1, 1) | -3031.04 | -3031.04 | 3.60072332311e-15 | 2.28327116973e-15 | 2.28327116973e-15 | PASS |
| diffStencilLaplacian | (0.125, 0) | -2.19535407223 | -2.19535407223 | 1.41600141329e-15 | 3.90900166402e-13 | 2.83125353722e-16 | PASS |
| RhieChow | (0, 0) | -0 | -6.93334779979e-32 | n/a | n/a | 2.16501356206e-17 | PASS |
| RhieChow | (0.5, 0) | -378.88 | -378.88 | 8.85177816931e-15 | 9.49619799914e-15 | 1.18702474989e-15 | PASS |
| RhieChow | (1, 0) | -1515.52 | -1515.52 | 3.15063290772e-15 | 2.86770567003e-15 | 1.43385283502e-15 | PASS |
| RhieChow | (0.5, 0.5) | -757.76 | -757.76 | 1.06521398309e-14 | 7.36249110145e-15 | 1.84062277536e-15 | PASS |
| RhieChow | (1, 0.5) | -1894.4 | -1894.4 | 1.80036166155e-15 | 3.94134469022e-15 | 2.46334043139e-15 | PASS |
| RhieChow | (0.5, 1) | -1894.4 | -1894.4 | 1.92038577232e-15 | 4.03979461751e-15 | 2.52487163594e-15 | PASS |
| RhieChow | (1, 1) | -3031.04 | -3031.04 | 3.60072332311e-15 | 2.28327116973e-15 | 2.28327116973e-15 | PASS |
| RhieChow | (0.125, 0) | -2.19535407223 | -2.19535407223 | 1.41600141329e-15 | 3.90900166402e-13 | 2.83125353722e-16 | PASS |

### 64x64x1

| Model (power) | theta/pi (x,y) | lambda_exact | lambda_num | rel lambda | E | E_ref | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| laplacian | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| laplacian | (0.5, 0) | -0.74 | -0.74 | 4.66593730619e-14 | 7.38528840438e-15 | 1.84632210109e-15 | PASS |
| laplacian | (1, 0) | -1.48 | -1.48 | 2.79056057541e-14 | 3.77638928224e-15 | 1.88819464112e-15 | PASS |
| laplacian | (0.5, 0.5) | -1.48 | -1.48 | 4.66593730619e-14 | 6.31737396765e-15 | 3.15868698383e-15 | PASS |
| laplacian | (1, 0.5) | -2.22 | -2.22 | 4.60092424619e-15 | 5.45371791233e-15 | 4.09028843425e-15 | PASS |
| laplacian | (0.5, 1) | -2.22 | -2.22 | 4.40088406158e-15 | 5.42906890995e-15 | 4.07180168246e-15 | PASS |
| laplacian | (1, 1) | -2.96 | -2.96 | 2.83556961695e-14 | 2.94386922573e-15 | 2.94386922573e-15 | PASS |
| laplacian | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 1.97095660881e-15 | 3.20743008989e-14 | 6.103776947e-16 | PASS |
| JamesonSchmidtTurkel | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| JamesonSchmidtTurkel | (0.5, 0) | -6062.08 | -6062.08 | 4.6359312785e-14 | 1.52959892883e-14 | 9.55999330519e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0) | -24248.32 | -24248.32 | 2.8205666031e-14 | 5.34910068873e-15 | 1.33727517218e-15 | PASS |
| JamesonSchmidtTurkel | (0.5, 0.5) | -24248.32 | -24248.32 | 4.6359312785e-14 | 9.74392509657e-15 | 2.43598127414e-15 | PASS |
| JamesonSchmidtTurkel | (1, 0.5) | -54558.72 | -54558.72 | 3.78742749542e-14 | 7.3353199709e-15 | 4.12611748363e-15 | PASS |
| JamesonSchmidtTurkel | (0.5, 1) | -54558.72 | -54558.72 | 3.85410755696e-14 | 6.92285377277e-15 | 3.89410524718e-15 | PASS |
| JamesonSchmidtTurkel | (1, 1) | -96993.28 | -96993.28 | 2.86557564464e-14 | 3.52879071032e-15 | 3.52879071032e-15 | PASS |
| JamesonSchmidtTurkel | (0.125, 0) | -35.1256651556 | -35.1256651556 | 7.08000706646e-15 | 1.02923261705e-12 | 3.72731804447e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0) | -0.74 | -0.74 | 4.66593730619e-14 | 7.38528840438e-15 | 1.84632210109e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0) | -1.48 | -1.48 | 2.79056057541e-14 | 3.77638928224e-15 | 1.88819464112e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0.5) | -1.48 | -1.48 | 4.66593730619e-14 | 6.31737396765e-15 | 3.15868698383e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0.5) | -2.22 | -2.22 | 4.60092424619e-15 | 5.45371791233e-15 | 4.09028843425e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 1) | -2.22 | -2.22 | 4.40088406158e-15 | 5.42906890995e-15 | 4.07180168246e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 1) | -2.96 | -2.96 | 2.83556961695e-14 | 2.94386922573e-15 | 2.94386922573e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 1.97095660881e-15 | 3.20743008989e-14 | 6.103776947e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0) | -6062.08 | -6062.08 | 4.6359312785e-14 | 1.52959892883e-14 | 9.55999330519e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0) | -24248.32 | -24248.32 | 2.8205666031e-14 | 5.34910068873e-15 | 1.33727517218e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0.5) | -24248.32 | -24248.32 | 4.6359312785e-14 | 9.74392509657e-15 | 2.43598127414e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0.5) | -54558.72 | -54558.72 | 3.78742749542e-14 | 7.3353199709e-15 | 4.12611748363e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 1) | -54558.72 | -54558.72 | 3.85410755696e-14 | 6.92285377277e-15 | 3.89410524718e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 1) | -96993.28 | -96993.28 | 2.86557564464e-14 | 3.52879071032e-15 | 3.52879071032e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.125, 0) | -35.1256651556 | -35.1256651556 | 7.08000706646e-15 | 1.02923261705e-12 | 3.72731804447e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0) | -12124.16 | -12124.16 | 3.84077154465e-14 | 6.08747957579e-14 | 9.51168683718e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0) | -96993.28 | -96993.28 | 2.74555153387e-14 | 1.06023856337e-14 | 1.32529820421e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0.5) | -96993.28 | -96993.28 | 4.14083182157e-14 | 1.96334394355e-14 | 2.45417992943e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0.5) | -327352.32 | -327352.32 | 5.60112516928e-14 | 1.05257833553e-14 | 4.44056485303e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 1) | -327352.32 | -327352.32 | 5.58334381954e-14 | 9.61400095324e-15 | 4.05590665215e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 1) | -775946.24 | -775946.24 | 2.8205666031e-14 | 5.7682007643e-15 | 5.7682007643e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.125, 0) | -5.347564105 | -5.347564105 | 7.80624316161e-15 | 4.15613810705e-11 | 2.86427252443e-16 | PASS |
| diffStencilLaplacian | (0, 0) | -0 | -6.47112461314e-31 | n/a | n/a | 2.3465057016e-17 | PASS |
| diffStencilLaplacian | (0.5, 0) | -1515.52 | -1515.52 | 4.65093429235e-14 | 1.73122141128e-14 | 2.1640267641e-15 | PASS |
| diffStencilLaplacian | (1, 0) | -6062.08 | -6062.08 | 2.79056057541e-14 | 5.44157048123e-15 | 2.72078524062e-15 | PASS |
| diffStencilLaplacian | (0.5, 0.5) | -3031.04 | -3031.04 | 4.6359312785e-14 | 1.43776040036e-14 | 3.5944010009e-15 | PASS |
| diffStencilLaplacian | (1, 0.5) | -7577.6 | -7577.6 | 4.71694755327e-14 | 7.7276619804e-15 | 4.82978873775e-15 | PASS |
| diffStencilLaplacian | (0.5, 1) | -7577.6 | -7577.6 | 4.72894996435e-14 | 7.62776546295e-15 | 4.76735341435e-15 | PASS |
| diffStencilLaplacian | (1, 1) | -12124.16 | -12124.16 | 2.83556961695e-14 | 4.1424141338e-15 | 4.1424141338e-15 | PASS |
| diffStencilLaplacian | (0.125, 0) | -8.78141628891 | -8.78141628891 | 6.87772115028e-15 | 7.8980823278e-13 | 5.72050754893e-16 | PASS |
| RhieChow | (0, 0) | -0 | -6.47112461314e-31 | n/a | n/a | 2.3465057016e-17 | PASS |
| RhieChow | (0.5, 0) | -1515.52 | -1515.52 | 4.65093429235e-14 | 1.73122141128e-14 | 2.1640267641e-15 | PASS |
| RhieChow | (1, 0) | -6062.08 | -6062.08 | 2.79056057541e-14 | 5.44157048123e-15 | 2.72078524062e-15 | PASS |
| RhieChow | (0.5, 0.5) | -3031.04 | -3031.04 | 4.6359312785e-14 | 1.43776040036e-14 | 3.5944010009e-15 | PASS |
| RhieChow | (1, 0.5) | -7577.6 | -7577.6 | 4.71694755327e-14 | 7.7276619804e-15 | 4.82978873775e-15 | PASS |
| RhieChow | (0.5, 1) | -7577.6 | -7577.6 | 4.72894996435e-14 | 7.62776546295e-15 | 4.76735341435e-15 | PASS |
| RhieChow | (1, 1) | -12124.16 | -12124.16 | 2.83556961695e-14 | 4.1424141338e-15 | 4.1424141338e-15 | PASS |
| RhieChow | (0.125, 0) | -8.78141628891 | -8.78141628891 | 6.87772115028e-15 | 7.8980823278e-13 | 5.72050754893e-16 | PASS |

### Additional anisotropic check: 16x16x1, hx=1/16, hy=1/8

| Model (power) | theta/pi (x,y) | lambda_exact | lambda_num | rel lambda | E | E_ref | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| laplacian | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| laplacian | (0.5, 0) | -0.74 | -0.74 | 1.05021096924e-15 | 2.47587669821e-15 | 6.18969174553e-16 | PASS |
| laplacian | (1, 0) | -1.48 | -1.48 | 2.10042193848e-15 | 1.06822419975e-15 | 5.34112099876e-16 | PASS |
| laplacian | (0.5, 0.5) | -1.48 | -1.48 | 1.2002411077e-15 | 2.08551288991e-15 | 1.04275644495e-15 | PASS |
| laplacian | (1, 0.5) | -2.22 | -2.22 | 4.20084387696e-15 | 1.58893116344e-15 | 1.19169837258e-15 | PASS |
| laplacian | (0.5, 1) | -2.22 | -2.22 | 4.00080369234e-15 | 1.60272337045e-15 | 1.20204252784e-15 | PASS |
| laplacian | (1, 1) | -2.96 | -2.96 | 1.95039180002e-15 | 7.83573154412e-16 | 7.83573154412e-16 | PASS |
| laplacian | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 2.71006533712e-15 | 9.7150198911e-15 | 1.84877963943e-16 | PASS |
| JamesonSchmidtTurkel | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| JamesonSchmidtTurkel | (0.5, 0) | -378.88 | -378.88 | 1.35027124617e-15 | 5.20687421107e-15 | 5.20687421107e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0) | -1515.52 | -1515.52 | 1.95039180002e-15 | 1.44774953842e-15 | 5.79099815369e-16 | PASS |
| JamesonSchmidtTurkel | (0.5, 0.5) | -947.2 | -947.2 | 3.2406509908e-15 | 3.48491036966e-15 | 8.71227592416e-16 | PASS |
| JamesonSchmidtTurkel | (1, 0.5) | -2557.44 | -2557.44 | 1.77813497437e-16 | 2.1036432038e-15 | 1.41995916257e-15 | PASS |
| JamesonSchmidtTurkel | (0.5, 1) | -1704.96 | -1704.96 | 8.00160738469e-16 | 2.25019248147e-15 | 1.01258661666e-15 | PASS |
| JamesonSchmidtTurkel | (1, 1) | -3788.8 | -3788.8 | 1.80036166155e-15 | 1.00872259012e-15 | 1.00872259012e-15 | PASS |
| JamesonSchmidtTurkel | (0.125, 0) | -2.19535407223 | -2.19535407223 | 2.22514507803e-15 | 3.02855247678e-13 | 1.75484190584e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0) | -0.74 | -0.74 | 1.05021096924e-15 | 2.47587669821e-15 | 6.18969174553e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0) | -1.48 | -1.48 | 2.10042193848e-15 | 1.06822419975e-15 | 5.34112099876e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 0.5) | -1.48 | -1.48 | 1.2002411077e-15 | 2.08551288991e-15 | 1.04275644495e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 0.5) | -2.22 | -2.22 | 4.20084387696e-15 | 1.58893116344e-15 | 1.19169837258e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.5, 1) | -2.22 | -2.22 | 4.00080369234e-15 | 1.60272337045e-15 | 1.20204252784e-15 | PASS |
| generalisedEvenOrderLaplacian (0) | (1, 1) | -2.96 | -2.96 | 1.95039180002e-15 | 7.83573154412e-16 | 7.83573154412e-16 | PASS |
| generalisedEvenOrderLaplacian (0) | (0.125, 0) | -0.0563291459416 | -0.0563291459416 | 2.71006533712e-15 | 9.7150198911e-15 | 1.84877963943e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0) | -378.88 | -378.88 | 1.35027124617e-15 | 5.20687421107e-15 | 5.20687421107e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0) | -1515.52 | -1515.52 | 1.95039180002e-15 | 1.44774953842e-15 | 5.79099815369e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 0.5) | -947.2 | -947.2 | 3.2406509908e-15 | 3.48491036966e-15 | 8.71227592416e-16 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 0.5) | -2557.44 | -2557.44 | 1.77813497437e-16 | 2.1036432038e-15 | 1.41995916257e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.5, 1) | -1704.96 | -1704.96 | 8.00160738469e-16 | 2.25019248147e-15 | 1.01258661666e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (1, 1) | -3788.8 | -3788.8 | 1.80036166155e-15 | 1.00872259012e-15 | 1.00872259012e-15 | PASS |
| generalisedEvenOrderLaplacian (1) | (0.125, 0) | -2.19535407223 | -2.19535407223 | 2.22514507803e-15 | 3.02855247678e-13 | 1.75484190584e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0, 0) | -0 | 0 | n/a | n/a | 0 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0) | -757.76 | -757.76 | 2.40048221541e-15 | 3.93279827398e-14 | 6.29247723837e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0) | -6062.08 | -6062.08 | 3.60072332311e-15 | 5.45457440741e-15 | 6.98185524148e-16 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 0.5) | -5920 | -5920 | 3.22624809751e-15 | 8.02142945877e-15 | 1.00267868235e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 0.5) | -23016.96 | -23016.96 | 1.26445153733e-15 | 3.75512365529e-15 | 1.82499009647e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.5, 1) | -15344.64 | -15344.64 | 3.67481228037e-15 | 3.74596161991e-15 | 1.21369156485e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (1, 1) | -47360 | -47360 | 3.84077154465e-15 | 2.12844681623e-15 | 2.12844681623e-15 | PASS |
| generalisedEvenOrderLaplacian (2) | (0.125, 0) | -0.334222756562 | -0.334222756562 | 1.16263196024e-15 | 1.93084688608e-11 | 1.36261184283e-16 | PASS |
| diffStencilLaplacian | (0, 0) | -0 | -1.77185554884e-31 | n/a | n/a | 2.54932798338e-17 | PASS |
| diffStencilLaplacian | (0.5, 0) | -94.72 | -94.72 | 1.2002411077e-15 | 5.28287783229e-15 | 1.05657556646e-15 | PASS |
| diffStencilLaplacian | (1, 0) | -378.88 | -378.88 | 2.40048221541e-15 | 1.64721182618e-15 | 1.31776946094e-15 | PASS |
| diffStencilLaplacian | (0.5, 0.5) | -118.4 | -118.4 | 2.88057865849e-15 | 4.91532230475e-15 | 1.22883057619e-15 | PASS |
| diffStencilLaplacian | (1, 0.5) | -402.56 | -402.56 | 2.68289188781e-15 | 2.34296850022e-15 | 1.99152322519e-15 | PASS |
| diffStencilLaplacian | (0.5, 1) | -189.44 | -189.44 | 1.35027124617e-15 | 3.35559684335e-15 | 1.34223873734e-15 | PASS |
| diffStencilLaplacian | (1, 1) | -473.6 | -473.6 | 1.56031344001e-15 | 1.40412500439e-15 | 1.40412500439e-15 | PASS |
| diffStencilLaplacian | (0.125, 0) | -0.548838518057 | -0.548838518057 | 8.49600847975e-15 | 2.23156455615e-13 | 2.58608231408e-16 | PASS |
| RhieChow | (0, 0) | -0 | -1.77185554884e-31 | n/a | n/a | 2.54932798338e-17 | PASS |
| RhieChow | (0.5, 0) | -94.72 | -94.72 | 1.2002411077e-15 | 5.28287783229e-15 | 1.05657556646e-15 | PASS |
| RhieChow | (1, 0) | -378.88 | -378.88 | 2.40048221541e-15 | 1.64721182618e-15 | 1.31776946094e-15 | PASS |
| RhieChow | (0.5, 0.5) | -118.4 | -118.4 | 2.88057865849e-15 | 4.91532230475e-15 | 1.22883057619e-15 | PASS |
| RhieChow | (1, 0.5) | -402.56 | -402.56 | 2.68289188781e-15 | 2.34296850022e-15 | 1.99152322519e-15 | PASS |
| RhieChow | (0.5, 1) | -189.44 | -189.44 | 1.35027124617e-15 | 3.35559684335e-15 | 1.34223873734e-15 | PASS |
| RhieChow | (1, 1) | -473.6 | -473.6 | 1.56031344001e-15 | 1.40412500439e-15 | 1.40412500439e-15 | PASS |
| RhieChow | (0.125, 0) | -0.548838518057 | -0.548838518057 | 8.49600847975e-15 | 2.23156455615e-13 | 2.58608231408e-16 | PASS |
