# convergenceMethodsComparison_all_v1.gnuplot
#
# Run from inside MomStab_summaries:
#   mkdir -p plots
#   gnuplot -e "YCOL=8; REFMESH=8; DATADIR='.'; OUTDIR='plots'" plotscripts/convergenceMethodsComparison_all_v1.gnuplot
#
# Optional single case:
#   gnuplot -e "CASE='cook10'; YCOL=8; REFMESH=8; DATADIR='.'; OUTDIR='plots'" plotscripts/convergenceMethodsComparison_all_v1.gnuplot
#
# This plots all stabilisation methods on one convergence plot per Cook case:
#   |d_y - d_{y,ref}| versus cells per side, N_side.
#
# YCOL=8 uses DyScaled; YCOL=7 uses raw Dy.
# REFMESH=8 uses the finest cook1 evenlap_m2 value as the common reference.

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

set xlabel "Cells per side"
set ylabel "|d_y - d_{y,ref}|"
set xtics ("3" 3, "6" 6, "12" 12, "24" 24, "48" 48, "96" 96, "192" 192, "384" 384)
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

# Reference-order guides.
set style line 11 lc rgb "#000000" dt (7,3) lw 1.5
set style line 12 lc rgb "#000000" dt (3,3) lw 1.5

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

    # X-range from all plotted meshes below REFMESH. All method files share the
    # same mesh sequence, so one representative file is enough here.
    stats file_m0 using (($1 < REFMESH) ? $2 : 1/0) nooutput
    minN = STATS_min
    maxN = STATS_max

    unset xrange
    unset yrange

    # Build rigorous visual bounds from every plotted data point:
    #   upper first-order guide:  y = A1 / x, with A1 > max(y_data*x_data)
    #   lower second-order guide: y = A2 / x^2, with A2 < min(y_data*x_data^2)
    # This keeps all data between the two guides at every data x-location.
    stats file_m0 using (($1 < REFMESH && abs(column(YCOL) - ref_m0) > 0) ? abs(column(YCOL) - ref_m0) : 1/0) nooutput
    minErr = STATS_min
    maxErr = STATS_max
    stats file_m0 using (($1 < REFMESH && abs(column(YCOL) - ref_m0) > 0) ? abs(column(YCOL) - ref_m0)*$2 : 1/0) nooutput
    maxYX = STATS_max
    stats file_m0 using (($1 < REFMESH && abs(column(YCOL) - ref_m0) > 0) ? abs(column(YCOL) - ref_m0)*$2*$2 : 1/0) nooutput
    minYX2 = STATS_min

    stats file_m1 using (($1 < REFMESH && abs(column(YCOL) - ref_m1) > 0) ? abs(column(YCOL) - ref_m1) : 1/0) nooutput
    minErr = (STATS_min < minErr ? STATS_min : minErr)
    maxErr = (STATS_max > maxErr ? STATS_max : maxErr)
    stats file_m1 using (($1 < REFMESH && abs(column(YCOL) - ref_m1) > 0) ? abs(column(YCOL) - ref_m1)*$2 : 1/0) nooutput
    maxYX = (STATS_max > maxYX ? STATS_max : maxYX)
    stats file_m1 using (($1 < REFMESH && abs(column(YCOL) - ref_m1) > 0) ? abs(column(YCOL) - ref_m1)*$2*$2 : 1/0) nooutput
    minYX2 = (STATS_min < minYX2 ? STATS_min : minYX2)

    stats file_m2 using (($1 < REFMESH && abs(column(YCOL) - ref_m2) > 0) ? abs(column(YCOL) - ref_m2) : 1/0) nooutput
    minErr = (STATS_min < minErr ? STATS_min : minErr)
    maxErr = (STATS_max > maxErr ? STATS_max : maxErr)
    stats file_m2 using (($1 < REFMESH && abs(column(YCOL) - ref_m2) > 0) ? abs(column(YCOL) - ref_m2)*$2 : 1/0) nooutput
    maxYX = (STATS_max > maxYX ? STATS_max : maxYX)
    stats file_m2 using (($1 < REFMESH && abs(column(YCOL) - ref_m2) > 0) ? abs(column(YCOL) - ref_m2)*$2*$2 : 1/0) nooutput
    minYX2 = (STATS_min < minYX2 ? STATS_min : minYX2)

    stats file_jst using (($1 < REFMESH && abs(column(YCOL) - ref_jst) > 0) ? abs(column(YCOL) - ref_jst) : 1/0) nooutput
    minErr = (STATS_min < minErr ? STATS_min : minErr)
    maxErr = (STATS_max > maxErr ? STATS_max : maxErr)
    stats file_jst using (($1 < REFMESH && abs(column(YCOL) - ref_jst) > 0) ? abs(column(YCOL) - ref_jst)*$2 : 1/0) nooutput
    maxYX = (STATS_max > maxYX ? STATS_max : maxYX)
    stats file_jst using (($1 < REFMESH && abs(column(YCOL) - ref_jst) > 0) ? abs(column(YCOL) - ref_jst)*$2*$2 : 1/0) nooutput
    minYX2 = (STATS_min < minYX2 ? STATS_min : minYX2)

    stats file_lap using (($1 < REFMESH && abs(column(YCOL) - ref_lap) > 0) ? abs(column(YCOL) - ref_lap) : 1/0) nooutput
    minErr = (STATS_min < minErr ? STATS_min : minErr)
    maxErr = (STATS_max > maxErr ? STATS_max : maxErr)
    stats file_lap using (($1 < REFMESH && abs(column(YCOL) - ref_lap) > 0) ? abs(column(YCOL) - ref_lap)*$2 : 1/0) nooutput
    maxYX = (STATS_max > maxYX ? STATS_max : maxYX)
    stats file_lap using (($1 < REFMESH && abs(column(YCOL) - ref_lap) > 0) ? abs(column(YCOL) - ref_lap)*$2*$2 : 1/0) nooutput
    minYX2 = (STATS_min < minYX2 ? STATS_min : minYX2)

    stats file_rc using (($1 < REFMESH && abs(column(YCOL) - ref_rc) > 0) ? abs(column(YCOL) - ref_rc) : 1/0) nooutput
    minErr = (STATS_min < minErr ? STATS_min : minErr)
    maxErr = (STATS_max > maxErr ? STATS_max : maxErr)
    stats file_rc using (($1 < REFMESH && abs(column(YCOL) - ref_rc) > 0) ? abs(column(YCOL) - ref_rc)*$2 : 1/0) nooutput
    maxYX = (STATS_max > maxYX ? STATS_max : maxYX)
    stats file_rc using (($1 < REFMESH && abs(column(YCOL) - ref_rc) > 0) ? abs(column(YCOL) - ref_rc)*$2*$2 : 1/0) nooutput
    minYX2 = (STATS_min < minYX2 ? STATS_min : minYX2)

    plotMinN = minN * 0.90
    plotMaxN = maxN * 1.10

    upperA = maxYX * 1.35
    lowerA = minYX2 * 0.65
    lowerA = ((lowerA / upperA) < plotMinN*0.70 ? lowerA : upperA*plotMinN*0.70)
    upperAtLeft = upperA / plotMinN
    lowerAtRight = lowerA / (plotMaxN**2)

    set xrange [plotMinN:plotMaxN]
    set yrange [lowerAtRight*0.75:upperAtLeft*1.35]

    # With x = N_side:
    # O(h)   = O(1/N_side)
    # O(h^2) = O(1/N_side^2)
    O1(x) = upperA / x
    O2(x) = lowerA / (x**2)

    unset label 11
    unset label 12
    labelX = plotMinN * (plotMaxN / plotMinN)**0.74
    set label 11 "1st order" at labelX,O1(labelX)*1.08 left font "Helvetica,9" textcolor rgb "#000000"
    set label 12 "2nd order" at labelX,O2(labelX)*1.25 left font "Helvetica,9" textcolor rgb "#000000"

    set output sprintf("%s/%s_convergenceMethodsComparison.pdf", OUTDIR, case)

    # Exclude zero errors on the log y-axis. Plot the even-Laplacian curves last
    # so their X markers match the visual priority of the tip-displacement plot.
    plot \
        file_jst using (($1 < REFMESH && abs(column(YCOL) - ref_jst) > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_jst)) with linespoints ls 4 title "JST", \
        file_lap using (($1 < REFMESH && abs(column(YCOL) - ref_lap) > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_lap)) with linespoints ls 5 title "Laplacian", \
        file_rc  using (($1 < REFMESH && abs(column(YCOL) - ref_rc)  > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_rc))  with linespoints ls 6 title "Rhie-Chow", \
        file_m0  using (($1 < REFMESH && abs(column(YCOL) - ref_m0)  > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_m0))  with linespoints ls 1 title "Even Laplacian, m=1", \
        file_m1  using (($1 < REFMESH && abs(column(YCOL) - ref_m1)  > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_m1))  with linespoints ls 2 title "Even Laplacian, m=2", \
        file_m2  using (($1 < REFMESH && abs(column(YCOL) - ref_m2)  > 0) ? $2 : 1/0):(abs(column(YCOL) - ref_m2))  with linespoints ls 3 title "Even Laplacian, m=3", \
        [plotMinN:plotMaxN] O1(x) with lines ls 11 notitle, \
        [plotMinN:plotMaxN] O2(x) with lines ls 12 notitle
}
