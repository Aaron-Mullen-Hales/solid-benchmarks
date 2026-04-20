set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "snesIterationsVsCells.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: SNES iterations"
set xlabel "Cells"
set ylabel "SNES iterations"
set grid
set key left top
set logscale x 2

plot for [col=2:6] "snesIterationsVsCells.dat" using 1:col with linespoints lw 2 pt 7 title columnhead(col)
