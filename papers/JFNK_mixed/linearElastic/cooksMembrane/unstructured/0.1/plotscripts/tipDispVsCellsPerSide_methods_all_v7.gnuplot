# tipDispVsCellsPerSide_methods_all_v7.gnuplot
#
# Run from inside MomStab_summaries:
#   mkdir -p plots
#   gnuplot -e "YCOL=8; REFMESH=7; DATADIR='.'; OUTDIR='plots'" plotscripts/tipDispVsCellsPerSide_methods_all_v7.gnuplot
#
# Optional single case:
#   gnuplot -e "CASE='cook1'; YCOL=8; REFMESH=7; DATADIR='.'; OUTDIR='plots'" plotscripts/tipDispVsCellsPerSide_methods_all_v7.gnuplot
#
# YCOL=8 uses DyScaled; YCOL=7 uses raw Dy.
# REFMESH=7 means mesh 7 is excluded from this displacement-vs-cells plot.

if (!exists("REFMESH")) REFMESH = 7
if (!exists("YCOL")) YCOL = 8
if (!exists("DATADIR")) DATADIR = "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
if (!exists("OUTDIR")) OUTDIR = "plots"
if (!exists("BENCHMARK_FILE")) BENCHMARK_FILE = "/Volumes/OpenFoam/aaronmullen-hales-v2312/solid-benchmarks/papers/JFNK_mixed/linearElastic/cooksMembrane/DataHPC/CookMembrane_summaries/Bijelona.csv"
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
set grid back dt 2 lw 0.50 lc rgb "#d9d9d9"

# Keep the shared legend inside the benchmark/convergence panel.
set key inside top right vertical Left reverse samplen 2.0 spacing 1.00 width 0 maxrows 7 nobox opaque font "Helvetica,13"

set xlabel "Cells per side"
set ylabel "Vertical displacement"
set xtics autofreq
set mxtics 2
set format y "%.2f"

set lmargin 7.5
set rmargin 2.0
set tmargin 1.2
set bmargin 3.8

# Method styling:
# - even-Laplacian methods are related, so use shades of red
# - even-Laplacian methods use X markers and are plotted last so they sit on top
# - other methods use distinct non-red colours/markers
#
# Gnuplot pt 2 is an X/cross-style marker in most terminals including pdfcairo.
set style line 1 lc rgb "#D7AAAA" pt 2 ps 0.80 lw 1.8 # evenlap m0, muted light red
set style line 2 lc rgb "#B85C4B" pt 2 ps 0.80 lw 1.8 # evenlap m1, muted brick red
set style line 3 lc rgb "#7A2738" pt 2 ps 0.80 lw 1.8 # evenlap m2, muted burgundy

set style line 4 lc rgb "#4C78A8" pt 5 ps 0.72 lw 1.6 # JST, muted blue square
set style line 5 lc rgb "#5B8E55" pt 7 ps 0.72 lw 1.6 # Laplacian, muted green circle
set style line 6 lc rgb "#7B6AA8" pt 9 ps 0.72 lw 1.6 # Rhie-Chow, muted purple triangle
set style line 7 lc rgb "#111111" dt (6,4) pt 9 ps 0.60 lw 1.6 # benchmark/reference

do for [case in cases] {
    file_m0  = sprintf("%s/%s_evenlap_m0.details.tsv", DATADIR, case)
    file_m1  = sprintf("%s/%s_evenlap_m1.details.tsv", DATADIR, case)
    file_m2  = sprintf("%s/%s_evenlap_m2.details.tsv", DATADIR, case)
    file_jst = sprintf("%s/%s_jst.details.tsv", DATADIR, case)
    file_lap = sprintf("%s/%s_laplacian.details.tsv", DATADIR, case)
    file_rc  = sprintf("%s/%s_rhiechow.details.tsv", DATADIR, case)
    bijelona = BENCHMARK_FILE

    set output sprintf("%s/%s_tipDispVsCellsPerSide.pdf", OUTDIR, case)

    # Exclude the reference mesh from this plot: $1 < REFMESH.
    # Plot the even-Laplacian curves last so their X markers are visually on top.
    plot \
        bijelona using 2:1 with linespoints ls 7 title "Benchmark", \
        file_jst using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 4 title "JST", \
        file_lap using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 5 title "Laplacian", \
        file_rc  using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 6 title "Rhie-Chow", \
        file_m0  using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 1 title "Even Laplacian, m=1", \
        file_m1  using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 2 title "Even Laplacian, m=2", \
        file_m2  using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 3 title "Even Laplacian, m=3"
}
