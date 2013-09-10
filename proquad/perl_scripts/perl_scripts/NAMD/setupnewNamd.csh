#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 


set pdb = $1 

mkdir $pdb 
cd $pdb 
\cp -rf $PDBDIR/$pdb.pdb  .
\cp -rf $SRC/NAMD/*inp . 
\cp -rf $SRC/NAMD/pdbalias . 
convertconfigtopdb.pl -outf config.namd -inf $SRC/NAMD/config.namd -pr $pdb 
source $SRC/NAMD/run.namd.csh $pdb 


