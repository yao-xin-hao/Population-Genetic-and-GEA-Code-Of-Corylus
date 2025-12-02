cut -f 1 Corylus.nosex > id.txt

for file in `ls ./Corylus.*.Q`;do
    paste id.txt ${file} > ${file}.result
done

for file in `ls ./Corylus.*.Q.result`;do
    python3 /data/00/user/user153/script/16.structure/admixture/kn.dataR.py ${file}
done
