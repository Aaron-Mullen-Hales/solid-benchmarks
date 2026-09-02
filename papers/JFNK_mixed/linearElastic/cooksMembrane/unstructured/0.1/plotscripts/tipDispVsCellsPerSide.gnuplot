set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
if (!exists("DATADIR")) DATADIR = "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
if (!exists("OUTDIR")) OUTDIR = "plots"
if (!exists("BENCHMARK_FILE")) BENCHMARK_FILE = "/Volumes/OpenFoam/aaronmullen-hales-v2312/solid-benchmarks/papers/JFNK_mixed/linearElastic/cooksMembrane/DataHPC/CookMembrane_summaries/Bijelona.csv"
system sprintf("mkdir -p %s", OUTDIR)
set output sprintf("%s/tipDispVsCellsPerSide.pdf", OUTDIR)

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: displacement comparison"
set xlabel "Number of cells per side"
set ylabel "Vertical corner displacement"
set grid
set key outside top center horizontal

datafile = sprintf("%s/tipDispScaledVsCellsPerSide.dat", DATADIR)
plot \
    BENCHMARK_FILE using 2:1 with linespoints lw 3 lc rgb "#000000" pt 7 title "Bijelona Benchmark", \
    for [col=2:*] datafile using 1:col with linespoints lw 2 pt 7 title columnhead(col)
