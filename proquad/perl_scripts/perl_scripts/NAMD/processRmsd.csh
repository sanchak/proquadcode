vmd -dispdev text -e rmsd.vmd
addCounter.pl -in rmsd.dat -out ooo

if(! -e RMSD) then 
   cp -r $SRC/NAMD/RMSD/ .
endif 

cd RMSD
./do.tikz.sh
cd -
