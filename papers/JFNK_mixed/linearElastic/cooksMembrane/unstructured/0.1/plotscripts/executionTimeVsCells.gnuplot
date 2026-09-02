set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
if (!exists("DATADIR")) DATADIR = "run_AMD_EPYC_9684X_96_Core_Processor_20260618_161649"
if (!exists("OUTDIR")) OUTDIR = "plots"
system sprintf("mkdir -p %s", OUTDIR)
set output sprintf("%s/executionTimeVsCells.pdf", OUTDIR)

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: execution time"
set xlabel "Cells"
set ylabel "Execution time [s]"
set grid
set key left top
set logscale x 2

datafile = sprintf("%s/executionTimeVsCells.dat", DATADIR)
plot for [col=2:*] datafile using 1:col with linespoints lw 2 pt 7 title columnhead(col)
