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
my $howmany = 100000 ;
my $verbose = 1 ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "protein=s"=>\$protein ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);



my @list= util_read_list_sentences($listfile);

foreach my $i (@list){
	my $uc = uc($i);
	print "mv $i.pdb $uc.pdb \n";
}


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
