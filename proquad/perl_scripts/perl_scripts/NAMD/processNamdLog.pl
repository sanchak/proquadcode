#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile,$protein);
my (@expressions);
my $cutoff ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "cutoff=i"=>\$cutoff ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
my $ofh = util_write($outfile);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a input file name => option -cutoff ") if(!defined $cutoff);
my $ifh = util_read($infile);

my $ofhenergy = util_write("out.energy");
my $ofhvol = util_write("out.vol");
my $ofhtemp = util_write("out.temp");

my $info = {};
my $cnt = $cutoff;
while(<$ifh>){
	$cnt++ ;
	if(/^ENERGY:/){
		my (@l) = split ; 
		my $temp = $l[12];
		my $step = $l[1];
		print $ofhenergy "$step $l[11]\n" if($step > $cutoff); 
		print $ofhtemp "$step $l[12]\n" if($step > $cutoff); 
		print $ofhvol "$step $l[18]\n" if($step > $cutoff);
	}
}

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
