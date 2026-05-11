set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "clockTimeVsCells.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: clock time"
set xlabel "Cells"
set ylabel "Clock time [s]"
set grid
set key left top
set logscale x 2

plot \
    "clockTimeVsCells.dat" using 1:2 with linespoints lw 2 pt 7 title columnhead(2), \
    "clockTimeVsCells.dat" using 1:3 with linespoints lw 2 pt 7 title columnhead(3), \
    "clockTimeVsCells.dat" using 1:4 with linespoints lw 2 pt 7 title columnhead(4), \
    "clockTimeVsCells.dat" using 1:5 with linespoints lw 2 pt 7 title columnhead(5), \
    "clockTimeVsCells.dat" using 1:6 with linespoints lw 2 pt 7 title columnhead(6), \
    "clockTimeVsCells.dat" using 1:7 with linespoints lw 2 pt 7 title columnhead(7)
