#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set list = $1

foreach i ( ` cat $list` )
  $SRC/NAMD/setupnewNamd.csh $i
end
