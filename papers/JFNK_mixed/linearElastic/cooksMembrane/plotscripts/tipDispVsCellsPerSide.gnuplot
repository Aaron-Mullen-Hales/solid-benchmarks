set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "tipDispVsCellsPerSide.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: displacement comparison"
set xlabel "Number of cells per side"
set ylabel "Vertical corner displacement"
set grid
set key outside top center horizontal

set style line 1 lc rgb "#1f77b4" pt 7 lw 2
set style line 2 lc rgb "#ff7f0e" pt 7 lw 2
set style line 3 lc rgb "#2ca02c" pt 7 lw 2
set style line 4 lc rgb "#d62728" pt 7 lw 2
set style line 5 lc rgb "#9467bd" pt 7 lw 2
set style line 6 lc rgb "#8c564b" pt 7 lw 2

plot \
    "Bijelona.csv" using 2:1 with linespoints lw 3 lc rgb "#000000" pt 7 title "Bijelona Benchmark", \
    "tipDispScaledVsCellsPerSide.dat" using 1:2 with linespoints ls 1 title columnhead(2), \
    "tipDispScaledVsCellsPerSide.dat" using 1:3 with linespoints ls 2 title columnhead(3), \
    "tipDispScaledVsCellsPerSide.dat" using 1:4 with linespoints ls 3 title columnhead(4), \
    "tipDispScaledVsCellsPerSide.dat" using 1:5 with linespoints ls 4 title columnhead(5), \
    "tipDispScaledVsCellsPerSide.dat" using 1:6 with linespoints ls 5 title columnhead(6), \
    "tipDispScaledVsCellsPerSide.dat" using 1:7 with linespoints ls 6 title columnhead(7)
