sed  's/^[ \t]*//;s/[ \t]*$//;s/[ \t]\+/\t/g' zscore.all |awk -F "[ \t,]" 'BEGIN{OFS="\t"}{print $3,$6,$9,$12,$15}' | awk -F "[ \t,]" 'BEGIN{OFS="\t"}{print ($1+$2+$3+$4+$5)/5}' > average.zcore
