#!/bin/csh 

if($#argv != 3  ) then 
  echo "Usage : ./generaterep.csh  outfile list.all list.specific"
  exit 
endif 

set out = $1
set listall = $2
set listspecific = $3

$SRC/MISC/extractHighestScoreFromAllOutFiles.pl -out $out -list $listall -single

echo Extracted in $SRC/SHELLSCRIPTS/getFreqSingle.csh
sort -n $out > ! $out.sorted 
$SRC/MISC/frequencyDistribution.pl -out $out.freqdist -in $out.sorted -max 200 -del 1

#specVSsensitity.pl -lis $out.sorted -tag $out -in $listspecific


\rm -f specificscores
touch specificscores 
foreach i ( ` cat $listspecific` )
    grep $i $out.sorted  >> specificscores
end
sort -n  specificscores > ! specificscores.sorted

#echo "-------------SPECIFIC SCORES last 2-------------"
#tail -2 specificscores.sorted



$SRC/PDBSEQRES/annotate.pl -pdb $out -in ~/pdb_seqres.txt -lis $out.sorted -out $out.sorted.annotated -cutoff 100 -caption $out  -scor -html . -header1 " Best matches when proteins are queried using the motif from protein $out" -header2 "( PAS - predicted active site, PD - potential difference,  DD - distance difference"


# gnu.csh $out



#ps2pdf /home/sandeepc/plot.eps 
#evince plot.pdf 
#plot  "iii.dat" using 2:1 smooth bezier title 'Frequency distribution for all proteins in PDB database'  with lines lc 3, "iii.dat" using 1:2  smooth bezier title 'Endonuclease'  with lines lc 5

