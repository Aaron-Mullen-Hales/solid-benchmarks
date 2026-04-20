set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "avgLinearIterationsVsCells.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: average linear iterations"
set xlabel "Cells"
set ylabel "Average linear iterations per SNES step"
set grid
set key left top
set logscale x 2

plot for [col=2:6] "avgLinearIterationsVsCells.dat" using 1:col with linespoints lw 2 pt 7 title columnhead(col)
