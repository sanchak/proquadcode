#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($config,$outfile,$which_tech,$driver,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "config=s"=>\$config ,
            "driver=s"=>\$driver ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
my $ofhdriver = util_write($driver);
my $ofhscript = util_write("run.csh");
usage( "Need to give a input file name => option -config ") if(!defined $config);
my $ifh = util_read($config);
#usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;

my $NAMDBIN = "/home/sandeepc/NAMD/namd2" ;

my $info = {};
while(<$ifh>){
     next if(/^\s*$/);
     next if(/^\s*#/);
	 s/=//g;
     chop ;
	 my ($nm,$junk) = split ; 
	$info->{$nm} = $junk; 
}


print $ofh <<'AAA';
package NamdConfig;
require Exporter;
@ISA = qw(Exporter );
use strict ;
use Carp ;
use FileHandle ;
use MyUtils ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;
my $MINDIST = 1 ; 
my $fields = {
AAA

foreach my $i (keys %{$info}){
	print $ofh "$i => undef,\n";
}


print $ofh <<'BBB';
};
sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

    #die "Please define TEST_HOME" if(!defined $ENV{TEST_HOME});
    bless $self, $class ; 
    $self ;
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: ->$attr()" unless exists $fields->{$attr} ; 
    $self->{$attr} = shift if @_;
    return $self->{$attr};
}

sub Read{
    my $self = shift;
    my $infile = shift;
    my $ifh = util_read($infile);
    while(<$ifh>){
         next if(/^\s*$/);
         next if(/#^\s*#/);
	     s/=//g;
         chop ;
	     my ($nm,$junk) = split ; 
         $self->{$nm} = $junk ;
    }
}
BBB

foreach my $i (keys %{$info}){
   print $ofh "sub Get$i\{ my \$self = shift; return \$self->{$i}; } \n";
}


############################## Driver ###########################################

print $ofhdriver <<'CCC';
#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyGeom;
use PDB;
use ConfigPDB;

use NamdConfig ;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($config,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "config=s"=>\$config ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -config ") if(!defined $config);
my $ifh = util_read($config);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();
my $PWD = cwd;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}

my $nc = new NamdConfig();

CCC


print $ofhdriver "######################### Please do not edit this file, copy it to the one you want to use#############################\n";
print $ofhdriver "\$nc->Read(\$config);\n";
foreach my $i (keys %{$info}){
   print $ofhdriver "my \$$i = \$nc->Get$i(); \n";
}


print $ofhdriver <<'DDD';

sub TEMPLATE{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);


   print $fh "exit\n";
}  

sub NamdRunsimsolvate{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);
   print $fh "############################################################# \n"; 
   print $fh "## JOB DESCRIPTION                                         ## \n"; 
   print $fh "############################################################# \n"; 
   print $fh "# Minimization and Equilibration of  \n"; 
   print $fh "# Ubiquitin in a Water Box \n"; 
   print $fh "############################################################# \n"; 
   print $fh "## ADJUSTABLE PARAMETERS                                   ## \n"; 
   print $fh "############################################################# \n"; 
   print $fh "structure          $PDBWBPSF.psf \n"; 
   print $fh "coordinates        $PDBWB.pdb  \n"; 
   print $fh "set temperature    $TEMP \n"; 
   print $fh "set outputname     $OUTPUTNAME \n"; 
   print $fh "firsttimestep      0 \n"; 
   print $fh "############################################################# \n"; 
   print $fh "## SIMULATION PARAMETERS                                   ## \n"; 
   print $fh "############################################################# \n"; 
   print $fh "# Input \n"; 
   print $fh "paraTypeCharmm	    on \n"; 
   print $fh "parameters          $PARAMFILE2 \n"; 
   print $fh "temperature         \$temperature \n"; 
   print $fh "# Force-Field Parameters \n"; 
   print $fh "exclude             scaled1-4 \n"; 
   print $fh "1-4scaling          1.0 \n"; 
   print $fh "cutoff              12.0 \n"; 
   print $fh "switching           on \n"; 
   print $fh "switchdist          10.0 \n"; 
   print $fh "pairlistdist        14.0 \n"; 
   print $fh "# Integrator Parameters \n"; 
   print $fh "timestep            $TIMESTEP  ;# 2fs/step \n"; 
   print $fh "rigidBonds          all  ;# needed for 2fs steps \n"; 
   print $fh "nonbondedFreq       1 \n"; 
   print $fh "fullElectFrequency  2   \n"; 
   print $fh "stepspercycle       10 \n"; 
   print $fh "# Constant Temperature Control \n"; 
   print $fh "langevin            on    ;# do langevin dynamics \n"; 
   print $fh "langevinDamping     1     ;# damping coefficient (gamma) of 1/ps \n"; 
   print $fh "langevinTemp        \$temperature \n"; 
   print $fh "langevinHydrogen    off    ;# don't couple langevin bath to hydrogens \n"; 
   print $fh "# Periodic Boundary Conditions \n"; 
   print $fh "cellBasisVector1    42.0    0.   0.0 \n"; 
   print $fh "cellBasisVector2     0.0  44.0   0.0 \n"; 
   print $fh "cellBasisVector3     0.0    0   47.0 \n"; 
   print $fh "cellOrigin          45.516 -1.303  1.750\n";
   print $fh "wrapAll             on \n"; 
   print $fh "# PME (for full-system periodic electrostatics) \n"; 
   print $fh "PME                 yes \n"; 
   print $fh "PMEGridSpacing      1.0 \n"; 
   print $fh "#manual grid definition \n"; 
   print $fh "#PMEGridSizeX        45 \n"; 
   print $fh "#PMEGridSizeY        45 \n"; 
   print $fh "#PMEGridSizeZ        48 \n"; 
   print $fh "# Constant Pressure Control (variable volume) \n"; 
   print $fh "useGroupPressure      yes ;# needed for rigidBonds \n"; 
   print $fh "useFlexibleCell       no \n"; 
   print $fh "useConstantArea       no \n"; 
   print $fh "langevinPiston        on \n"; 
   print $fh "langevinPistonTarget  1.01325 ;#  in bar -> 1 atm \n"; 
   print $fh "langevinPistonPeriod  100.0 \n"; 
   print $fh "langevinPistonDecay   50.0 \n"; 
   print $fh "langevinPistonTemp    \$temperature \n"; 
   print $fh "# Output \n"; 
   print $fh "outputName          \$outputname \n"; 
   print $fh "restartfreq         500     ;# 500steps = every 1ps \n"; 
   print $fh "dcdfreq             250 \n"; 
   print $fh "xstFreq             250 \n"; 
   print $fh "outputEnergies      100 \n"; 
   print $fh "outputPressure      100 \n"; 
   print $fh "############################################################# \n"; 
   print $fh "## EXTRA PARAMETERS                                        ## \n"; 
   print $fh "############################################################# \n"; 
   print $fh "############################################################# \n"; 
   print $fh "## EXECUTION SCRIPT                                        ## \n"; 
   print $fh "############################################################# \n"; 
   print $fh "# Minimization \n"; 
   print $fh "minimize            $MINIMIZECYCLES \n"; 
   print $fh "reinitvels          \$temperature \n"; 
   print $fh "run $CYCLES ;# 5ps \n"; 
   print $fh "exit\n";
}  


sub WriteSolvate{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);
   print $fh "package require solvate\n";
   print $fh "solvate $PDBPSF.psf $PDBPSF.pdb -t $WATERLAYER -o $PDBWB\n";
   print $fh "exit\n";
}

sub WriteMinMax{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);
   print $fh "set mol [mol new $PDBWB.pdb type pdb waitfor all]\n";
   print $fh "set toppdb [atomselect top protein]\n";
   print $fh "set everyone [atomselect top all]\n";
   print $fh "measure minmax \$everyone\n";
   print $fh "measure center \$everyone\n";
   print $fh "exit\n";
}

sub WriteRemoveH{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);
   print $fh "set mol [mol new $PDB.pdb type pdb waitfor all]\n";
   print $fh "set toppdb [atomselect top protein]\n";
   print $fh "\$toppdb writepdb $PDBNoH.pdb\n";
   print $fh "exit\n";
}


sub WritePSF{
   my ($fname) = @_ ;
   print "Writing $fname \n";
   my $fh = util_write($fname);
   print $fh "package require psfgen\n";
   print $fh "topology $PARAMFILE1\n";
   if(-e $PDBALIAS){
      my $ifh = util_read($PDBALIAS);
      while(<$ifh>){
         print $fh $_ ;
      }
   }
   print $fh "segment U {pdb $PDBNoH.pdb}\n";
   print $fh "coordpdb $PDBNoH.pdb U\n";
   print $fh "guesscoord\n";
   print $fh "writepdb $PDBPSF.pdb\n";
   print $fh "writepsf $PDBPSF.psf\n";
   print $fh "exit\n";
}

WriteRemoveH("removeH.vmd");
WritePSF("psf.vmd");
WriteSolvate("solvate.vmd");
WriteMinMax("minmax.vmd");
NamdRunsimsolvate("runsimsolvate.conf");


DDD

print $ofhscript "  unlink \$1.pdb ; cp -rf $PDBDIR/\$1.pdb . \n";
print $ofhscript " echo \"Running remove h\" ;  vmd -dispdev text -e removeH.vmd > & ! removeH.log\n";
print $ofhscript "  echo \"Running psf\" ; vmd -dispdev text -e psf.vmd > & ! psf.log\n";
print $ofhscript "  echo \"Running solvate\" ; vmd -dispdev text -e solvate.vmd > & ! solvate.log\n";
print $ofhscript "  echo \"Running minmax\" ; vmd -dispdev text -e minmax.vmd > & ! minmax.log\n";
print $ofhscript "  \$SRC/NAMD/extractCentrefromminmax.pl -outf lll -log minmax.log -con runsimsolvate.conf \n";
print $ofhscript "   mv -f lll runsimsolvate.conf\n";
print $ofhscript "  echo \"Running runsimsolvate\" ; $NAMDBIN  runsimsolvate.conf > & ! runsimsolvate.log\n";

############################## Driver ends ###########################################

print "Wrote files $outfile and $driver\n";
chmod 0777, $outfile ;
chmod 0777, $driver ;

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
