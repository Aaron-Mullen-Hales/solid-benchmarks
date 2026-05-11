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

plot \
    "maxMemoryVsCells.dat" using 1:2 with linespoints lw 2 pt 7 title columnhead(2), \
    "maxMemoryVsCells.dat" using 1:3 with linespoints lw 2 pt 7 title columnhead(3), \
    "maxMemoryVsCells.dat" using 1:4 with linespoints lw 2 pt 7 title columnhead(4), \
    "maxMemoryVsCells.dat" using 1:5 with linespoints lw 2 pt 7 title columnhead(5), \
    "maxMemoryVsCells.dat" using 1:6 with linespoints lw 2 pt 7 title columnhead(6), \
    "maxMemoryVsCells.dat" using 1:7 with linespoints lw 2 pt 7 title columnhead(7)
