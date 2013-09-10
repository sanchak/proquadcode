#!/usr/bin/perl -w 
use strict ;
use PDB;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use MyPymol;
use Math::Geometry ;
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors




use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($ann,$config,$p1,$p2,$infile,$ignorepro,$outfile,$which_tech,$listfile,$protein);
my $maxdist ;
my $DISTANCEWITHOUTSEQMATCH = 1 ;
my $verbose = 1 ;

my ($verify,$radii,$before1,$before2);
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "verify"=>\$verify ,
            "p1=s"=>\$p1 ,
            "p2=s"=>\$p2 ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "outfile=s"=>\$outfile ,
            "ann=s"=>\$ann ,
            "maxdist=f"=>\$maxdist ,
            "config=s"=>\$config,
            "ignorepro"=>\$ignorepro,
            "radii=i"=>\$radii ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a output file name => option -outfile ") if(!defined $outfile);
usage( "Need to give a config file name => option -config ") if(!defined $config);
usage( "Need to give a listfile -option -list  ") if(!defined $listfile);
my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();

my @list= util_read_list_sentences($listfile);
my $list = {};
map { s/\s*//g ; $list->{$_} = 1 ; } @list ;

foreach my $protein (@list){
     my $ofhmean = util_write("mean.$protein");
    my $ofhsd = util_write("sd.$protein");
    my $PWD = cwd;

    ConfigPDB_Init($config);
    
    my $i = $protein ;
    my @proteins ; 
    push @proteins, $i ; 
    next if( ! -e "$APBSDIR/$i/$i.pqr");
    next if( ! -e "$APBSDIR/$i/pot1.dx.atompot" && ! -e "$APBSDIR/$i/pot1.dx.atompot");
    my @info = util_ReadPdbs($PDBDIR,$APBSDIR,1,@proteins) ; 
    my $info = shift @info ;
    my $pdb1 = $info->{PDBOBJ};
    my $pqr1 = $info->{PQR};
    my $pots1 = $info->{POTS};
    
    #push @pots, $pot ;
    my @res = $pdb1->GetResidues();
    my $N = @res;
    my $cnt = 0 ; 
    my $prevres ; 
    my $prevpd = 0  ; 
    my @potCA ; 
    #while(@res){
	#my $mainres = shift @res ;
    #my $MAINCA = $pdb1->GetAtomFromResidueAndType($mainres->GetResNum(),"CA");
    #my $potmain = util_GetPotForAtom($MAINCA,$pqr1,$pots1) *1  ;
	my $bad = 0 ; 
	my $N = @res ; 
	my @removedres ; 
    foreach my $res (@res){
	    my $resnum = $res->GetResNum();
	    my $name = $res->GetName();
	    if(defined $ignorepro && $name eq "PRO"){
			pop @removedres;
			shift @res ; 
		}
		else{
			push @removedres, $res ; 
		}
	}
    foreach my $res (@removedres){
        next if($res->GetAtomStr() ne "ATOM");
        $cnt++;
		next if($cnt <= 2) ;
		next if(abs($cnt -$N) <=2 ) ;
	    my $resnum = $res->GetResNum();
	    my $name = $res->GetName();
	    next if(defined $ignorepro && $name eq "PRO");
        
        my $CA = $pdb1->GetAtomFromResidueAndType($resnum,"CA");
		if(!defined $CA){
		   $bad = 1  ;
		   last ;
		}
		#my $d = util_format_float($pdb1->DistanceAtoms($CA,$MAINCA),1);
		#next if($d > 6 );

        my $potCA = util_GetPotForAtom($CA,$pqr1,$pots1) *1  ;
    
	    #my $pd = $potmain - $potCA ; 
	    #push @potCA, $pd ; 
	    push @potCA, $potCA ; 
    
    }
	#}
    
	next if($bad);
    my ($mean,$sd) = util_GetMeanSD(\@potCA);
    print $ofhmean "$mean \n";
    print $ofhsd "$sd \n";
}


    

sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
