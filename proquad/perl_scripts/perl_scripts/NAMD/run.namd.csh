namdconfig.pl -con config.namd -outf NamdConfig.pm -dr namddriver.pl 
./namddriver.pl -con config.namd
source run.csh $1 
