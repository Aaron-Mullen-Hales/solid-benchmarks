set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "tipDispErrorVsCells.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: displacement error"
set xlabel "Cells"
set ylabel "Absolute vertical corner displacement error"
set grid
set key left bottom
set logscale x 2
set logscale y

set style line 1 lc rgb "#1f77b4" pt 7 lw 2
set style line 2 lc rgb "#ff7f0e" pt 7 lw 2
set style line 3 lc rgb "#2ca02c" pt 7 lw 2
set style line 4 lc rgb "#d62728" pt 7 lw 2
set style line 5 lc rgb "#9467bd" pt 7 lw 2
set style line 6 lc rgb "#8c564b" pt 7 lw 2

errorData = "< awk 'function a(x){return x<0?-x:x} NR==1{next} {n++; cells[n]=$1; d2[n]=$2*0.001; d3[n]=$3*0.001; d4[n]=$4*0.001; d5[n]=$5*0.001; d6[n]=$6*0.001; d7[n]=$7*0.001} END{ref=d7[n]; for(i=1; i<n; i++) printf \"%g\\t%.12g\\t%.12g\\t%.12g\\t%.12g\\t%.12g\\t%.12g\\n\", cells[i], a(d2[i]-ref), a(d3[i]-ref), a(d4[i]-ref), a(d5[i]-ref), a(d6[i]-ref), a(d7[i]-ref)}' tipDispVsCells.dat"

plot \
    errorData using 1:2 with linespoints ls 1 title "rhiechow", \
    errorData using 1:3 with linespoints ls 2 title "laplacian", \
    errorData using 1:4 with linespoints ls 3 title "jst", \
    errorData using 1:5 with linespoints ls 4 title "evenlap_m0", \
    errorData using 1:6 with linespoints ls 5 title "evenlap_m1", \
    errorData using 1:7 with linespoints ls 6 title "evenlap_m2"
