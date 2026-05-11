set terminal pdfcairo enhanced color size 7,5 font "Helvetica,10"
set output "clockTimeVsTipDispError.pdf"

set datafile separator whitespace
set datafile missing "NaN"
set title "Cook's membrane: clock time versus displacement error"
set xlabel "Clock time [s]"
set ylabel "Absolute vertical corner displacement error"
set grid
set key right top
set logscale x
set logscale y

set style line 1 lc rgb "#1f77b4" pt 7 lw 2
set style line 2 lc rgb "#ff7f0e" pt 7 lw 2
set style line 3 lc rgb "#2ca02c" pt 7 lw 2
set style line 4 lc rgb "#d62728" pt 7 lw 2
set style line 5 lc rgb "#9467bd" pt 7 lw 2
set style line 6 lc rgb "#8c564b" pt 7 lw 2

clockErrorData = "< awk 'function a(x){return x<0?-x:x} FNR==NR{if(FNR>1){n++; d2[n]=$2*0.001; d3[n]=$3*0.001; d4[n]=$4*0.001; d5[n]=$5*0.001; d6[n]=$6*0.001; d7[n]=$7*0.001} next} FNR>1{m++; t2[m]=$2; t3[m]=$3; t4[m]=$4; t5[m]=$5; t6[m]=$6; t7[m]=$7} END{ref=d7[n]; last=(n<m?n:m); for(i=1; i<last; i++) printf \"%g\\t%.12g\\t%g\\t%.12g\\t%g\\t%.12g\\t%g\\t%.12g\\t%g\\t%.12g\\t%g\\t%.12g\\n\", t2[i], a(d2[i]-ref), t3[i], a(d3[i]-ref), t4[i], a(d4[i]-ref), t5[i], a(d5[i]-ref), t6[i], a(d6[i]-ref), t7[i], a(d7[i]-ref)}' tipDispVsCells.dat clockTimeVsCells.dat"

plot \
    clockErrorData using 1:2 with linespoints ls 1 title "rhiechow", \
    clockErrorData using 3:4 with linespoints ls 2 title "laplacian", \
    clockErrorData using 5:6 with linespoints ls 3 title "jst", \
    clockErrorData using 7:8 with linespoints ls 4 title "evenlap_m0", \
    clockErrorData using 9:10 with linespoints ls 5 title "evenlap_m1", \
    clockErrorData using 11:12 with linespoints ls 6 title "evenlap_m2"
