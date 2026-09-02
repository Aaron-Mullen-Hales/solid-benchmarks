# clockTimeVsTipDispError.gnuplot
#
# Historical filename kept for compatibility. This script now plots execution
# time, not rounded clock time.
#
# Run from inside MomStab_summaries:
#   mkdir -p plots
#   gnuplot -e "YCOL=8; REFMESH=8; DATADIR='.'; OUTDIR='plots'" plotscripts/clockTimeVsTipDispError.gnuplot
#
# Optional single case:
#   gnuplot -e "CASE='cook1'; YCOL=8; REFMESH=8; DATADIR='.'; OUTDIR='plots'" plotscripts/clockTimeVsTipDispError.gnuplot
#
# This plots:
#   |d_y - d_{y,ref}| versus execution time.
#
# YCOL=8 uses DyScaled; YCOL=7 uses raw Dy.
# REFMESH=8 uses the finest cook1 evenlap_m2 value as the common reference.
# The visible data remain meshes 2--7.

if (!exists("REFMESH")) REFMESH = 8
if (!exists("YCOL")) YCOL = 8
if (!exists("DATADIR")) DATADIR = "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
if (!exists("OUTDIR")) OUTDIR = "plots"
if (!exists("COMMON_REFFILE")) COMMON_REFFILE = "/Volumes/OpenFoam/aaronmullen-hales-v2312/solid-benchmarks/papers/JFNK_mixed/linearElastic/cooksMembrane/DataHPC/CookMembrane_summaries/cook1_evenlap_m2.details.tsv"
system sprintf("mkdir -p %s", OUTDIR)

cases = exists("CASE") ? CASE : "pabloMesh"

set terminal pdfcairo enhanced color size 7.0,4.8 font "Helvetica,10"
set datafile separator whitespace
set datafile commentschars "#"
set datafile missing "NaN"

set encoding utf8
unset title
set border lw 1.2
set tics nomirror out scale 0.75
set logscale x
set logscale y
set grid back dt 2 lw 0.50 lc rgb "#d9d9d9"

# The displacement-vs-mesh panel carries the shared method legend.
unset key

set xlabel "Execution time [s]"
set ylabel "|d_y - d_{y,ref}|"
set format x "%g"
set format y "10^{%T}"

set lmargin 7.5
set rmargin 2.0
set tmargin 1.2
set bmargin 3.8

# Same method styling as tipDispVsCellsPerSide_methods_all_v7.gnuplot.
set style line 1 lc rgb "#D7AAAA" pt 2 ps 0.80 lw 1.8
set style line 2 lc rgb "#B85C4B" pt 2 ps 0.80 lw 1.8
set style line 3 lc rgb "#7A2738" pt 2 ps 0.80 lw 1.8

set style line 4 lc rgb "#4C78A8" pt 5 ps 0.72 lw 1.6
set style line 5 lc rgb "#5B8E55" pt 7 ps 0.72 lw 1.6
set style line 6 lc rgb "#7B6AA8" pt 9 ps 0.72 lw 1.6

do for [case in cases] {
    file_m0  = sprintf("%s/%s_evenlap_m0.details.tsv", DATADIR, case)
    file_m1  = sprintf("%s/%s_evenlap_m1.details.tsv", DATADIR, case)
    file_m2  = sprintf("%s/%s_evenlap_m2.details.tsv", DATADIR, case)
    file_jst = sprintf("%s/%s_jst.details.tsv", DATADIR, case)
    file_lap = sprintf("%s/%s_laplacian.details.tsv", DATADIR, case)
    file_rc  = sprintf("%s/%s_rhiechow.details.tsv", DATADIR, case)

    unset xrange
    unset yrange

    stats COMMON_REFFILE using (($1 == REFMESH) ? column(YCOL) : 1/0) nooutput
    common_ref = STATS_min
    ref_m0 = common_ref
    ref_m1 = common_ref
    ref_m2 = common_ref
    ref_jst = common_ref
    ref_lap = common_ref
    ref_rc = common_ref

    set output sprintf("%s/%s_executionTimeVsTipDispError.pdf", OUTDIR, case)

    # ExecutionTime is column 4. Use meshes 2 through REFMESH-1; mesh 1 is
    # intentionally excluded and mesh REFMESH is only the reference solution.
    # Exclude zero errors and non-positive timings because both axes are
    # logarithmic. Plot even-Laplacian curves last so their X markers match the
    # visual priority of the displacement plot.
    plot \
        file_jst using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_jst) > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_jst)) with linespoints ls 4 title "JST", \
        file_lap using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_lap) > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_lap)) with linespoints ls 5 title "Laplacian", \
        file_rc  using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_rc)  > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_rc))  with linespoints ls 6 title "Rhie-Chow", \
        file_m0  using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_m0)  > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_m0))  with linespoints ls 1 title "Even Laplacian, m=1", \
        file_m1  using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_m1)  > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_m1))  with linespoints ls 2 title "Even Laplacian, m=2", \
        file_m2  using (($1 >= 2 && $1 < REFMESH && $4 > 0 && abs(column(YCOL) - ref_m2)  > 0) ? $4 : 1/0):(abs(column(YCOL) - ref_m2))  with linespoints ls 3 title "Even Laplacian, m=3"
}
