# tipDispVsCellsPerSide_evenlap_scales.gnuplot
#
# Run from inside MomStab_summaries:
#   mkdir -p plots
#   gnuplot -e "YCOL=8; REFMESH=7; DATADIR='.'; OUTDIR='plots'" plotscripts/tipDispVsCellsPerSide_evenlap_scales.gnuplot
#
# Produces four plots:
#   1. all even-Laplacian methods, grouped by stabilisation scale
#   2. m=0 only, all stabilisation scales
#   3. m=1 only, all stabilisation scales
#   4. m=2 only, all stabilisation scales
#
# YCOL=8 uses DyScaled; YCOL=7 uses raw Dy.
# REFMESH=7 excludes the finest plotted method mesh, while keeping all
# Bijelona benchmark/reference points.

if (!exists("REFMESH")) REFMESH = 7
if (!exists("YCOL")) YCOL = 8
if (!exists("DATADIR")) DATADIR = "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
if (!exists("OUTDIR")) OUTDIR = "plots"
if (!exists("BENCHMARK_FILE")) BENCHMARK_FILE = "/Volumes/OpenFoam/aaronmullen-hales-v2312/solid-benchmarks/papers/JFNK_mixed/linearElastic/cooksMembrane/DataHPC/CookMembrane_summaries/Bijelona.csv"
system sprintf("mkdir -p %s", OUTDIR)

set terminal pdfcairo enhanced color size 7.0,4.8 font "Helvetica,10"
set datafile separator whitespace
set datafile commentschars "#"
set datafile missing "NaN"

set encoding utf8
unset title
set border lw 1.2
set tics nomirror out scale 0.75
set grid back lw 0.65 lc rgb "#dddddd"
set key outside top center horizontal samplen 2.3 spacing 1.10 width 1 maxrows 4 box lw 0.6 opaque

set xlabel "Cells per side"
set ylabel "Vertical displacement"
set xtics autofreq
set mxtics 2
set format y "%.2f"

set lmargin 7.5
set rmargin 2.0
set tmargin 5.0
set bmargin 3.8

bijelona = BENCHMARK_FILE
file_m0 = sprintf("%s/pabloMesh_evenlap_m0.details.tsv", DATADIR)
file_m1 = sprintf("%s/pabloMesh_evenlap_m1.details.tsv", DATADIR)
file_m2 = sprintf("%s/pabloMesh_evenlap_m2.details.tsv", DATADIR)
scale_label = "0.1"
ls_m0 = 4
ls_m1 = 5
ls_m2 = 6

# Scale-factor palettes. Within each scale, m=0 is lightest and m=2 darkest.
set style line 1  lc rgb "#dadaeb" pt 2 ps 0.95 lw 2.0 # 0.01 m0
set style line 2  lc rgb "#9e9ac8" pt 2 ps 0.95 lw 2.2 # 0.01 m1
set style line 3  lc rgb "#54278f" pt 2 ps 0.95 lw 2.4 # 0.01 m2
set style line 4  lc rgb "#bdd7e7" pt 2 ps 0.95 lw 2.0 # 0.1 m0
set style line 5  lc rgb "#6baed6" pt 2 ps 0.95 lw 2.2 # 0.1 m1
set style line 6  lc rgb "#08519c" pt 2 ps 0.95 lw 2.4 # 0.1 m2
set style line 7  lc rgb "#c7eae5" pt 2 ps 0.95 lw 2.0 # 1 m0
set style line 8  lc rgb "#5ab4ac" pt 2 ps 0.95 lw 2.2 # 1 m1
set style line 9  lc rgb "#01665e" pt 2 ps 0.95 lw 2.4 # 1 m2
set style line 10 lc rgb "#c7e9c0" pt 2 ps 0.95 lw 2.0 # 10 m0
set style line 11 lc rgb "#74c476" pt 2 ps 0.95 lw 2.2 # 10 m1
set style line 12 lc rgb "#006d2c" pt 2 ps 0.95 lw 2.4 # 10 m2
set style line 13 lc rgb "#fdd0a2" pt 2 ps 0.95 lw 2.0 # 100 m0
set style line 14 lc rgb "#fd8d3c" pt 2 ps 0.95 lw 2.2 # 100 m1
set style line 15 lc rgb "#d94801" pt 2 ps 0.95 lw 2.4 # 100 m2
set style line 16 lc rgb "#fcbba1" pt 2 ps 0.95 lw 2.0 # 1000 m0
set style line 17 lc rgb "#fb6a4a" pt 2 ps 0.95 lw 2.2 # 1000 m1
set style line 18 lc rgb "#a50f15" pt 2 ps 0.95 lw 2.4 # 1000 m2
set style line 99 lc rgb "#111111" dt (6,4) pt 9 ps 0.65 lw 2.4 # benchmark/reference

set output sprintf("%s/evenlap_scales_all_tipDispVsCellsPerSide.pdf", OUTDIR)
plot \
    bijelona using 2:1 with linespoints ls 99 title "Benchmark", \
    file_m0 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 4 title sprintf("%s, m=0", scale_label), \
    file_m1 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 5 title sprintf("%s, m=1", scale_label), \
    file_m2 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 6 title sprintf("%s, m=2", scale_label)

set key outside top center horizontal samplen 2.3 spacing 1.10 width 1 maxrows 2 box lw 0.6 opaque

set output sprintf("%s/evenlap_scales_m0_tipDispVsCellsPerSide.pdf", OUTDIR)
plot \
    bijelona using 2:1 with linespoints ls 99 title "Benchmark", \
    file_m0 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 4 title scale_label

set output sprintf("%s/evenlap_scales_m1_tipDispVsCellsPerSide.pdf", OUTDIR)
plot \
    bijelona using 2:1 with linespoints ls 99 title "Benchmark", \
    file_m1 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 5 title scale_label

set output sprintf("%s/evenlap_scales_m2_tipDispVsCellsPerSide.pdf", OUTDIR)
plot \
    bijelona using 2:1 with linespoints ls 99 title "Benchmark", \
    file_m2 using (($1 < REFMESH) ? $2 : 1/0):(column(YCOL)) with linespoints ls 6 title scale_label
