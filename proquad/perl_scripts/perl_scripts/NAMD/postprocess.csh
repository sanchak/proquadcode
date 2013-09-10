#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set finalpbd = $2
set newlist = $PWD/list.new

newfile.csh $newlist


foreach ref ( ` cat $listref` )
  cd $ref 	
  echo $ref 

  if(! -e $finalpbd) then
  	  echo writing frames
      vmd -dispdev text -e writeframes.vmd  > & ! log 
  endif 

  processNamdLog.pl -out ooo -in runsimsolvate.log
  if(-e $finalpbd) then 
     \cp -f $finalpbd $PWD/${ref}LASTFRAME.pdb 
	 echo ${ref}LASTFRAME >> $newlist
	 echo ${ref} >> $newlist
  endif 

  cd - 
end

