set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "maxMemoryVsCells.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: max memory"
set xlabel "Cells"
set ylabel "Max memory [MB]"
set grid
set key left top
set logscale x 2

plot for [col=2:6] "maxMemoryVsCells.dat" using 1:col with linespoints lw 2 pt 7 title columnhead(col)
