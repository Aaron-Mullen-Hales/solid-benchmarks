set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "tipDispVsCellsPerSide.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: displacement comparison"
set xlabel "Number of cells per side"
set ylabel "Vertical corner displacement"
set grid
set key outside top center horizontal

plot \
    "Bijelona.csv" using 2:1 with linespoints lw 3 lc rgb "#000000" pt 7 title "Bijelona Benchmark", \
    for [col=2:6] "tipDispScaledVsCellsPerSide.dat" using 1:col with linespoints lw 2 pt 7 title columnhead(col)
