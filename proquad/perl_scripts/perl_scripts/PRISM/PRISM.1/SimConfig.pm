
package SimConfig;
use MyUtils;
use PDB;
use Atom;
use Residue;
use MyGeom;
require Exporter;
use ConfigPDB;
use AAConfig;
use SimNode;
use SimState;

@ISA = qw(Exporter );

use strict ;
use Carp ;
use FileHandle ;
use Getopt::Long;
use vars qw($AUTOLOAD);
use Getopt::Long;
use File::Basename;

my $MINDIST = 1 ; 
my $statesseen = {};

my $SIGDIFFERENCEINPOT = 50 ; 
my $DIFFFORMOVE = 150 ; 
my $DIFFFORMOVETOBASIC = 100 ; 
my $DIFFFORMOVEFROMBASIC = 300 ; 

my $fields = {
    POT => undef, 
    PDB => undef, 
    INDICES => undef, 
    AACONFIG => undef, 
    SIMNODES => undef, 
    ATOMIDX => undef, 
    MOVETABLE => undef, 
};

sub new{
    my $that = shift ; 
    my $class = ref($that) || $that ;
	my ($indices,$simnodes,$pdb,$pqr,$pots,$idx,$delforpot) = @_ ; 

    my $self = {} ; 
    map { $self->{$_} = undef ; } (keys %{$fields});

    my $table = {};
	$table->{"1a2b"} = 50 - $delforpot ;
	$table->{"1b2a"} = 400 - $delforpot ; 
	$table->{"1a2a"} = 150 - $delforpot ; 
	$table->{"1b2b"} = 300 - $delforpot ; 
	$table->{"1x2b"} = 100 - $delforpot ; 
	$table->{"1x2m"} = 250 - $delforpot ; 
	$table->{"1b2p"} = 400 - $delforpot ; 
	$table->{"1m2x"} = 151 - $delforpot ; 

	$self->{PDB} = $pdb ;
	$self->{INDICES} = $indices;
	$self->{SIMNODES} = $simnodes;
	$self->{ATOMIDX} = $idx;
	$self->{AACONFIG} = new AAConfig("/home/sandeepc/aa.config");
	$self->{MOVETABLE} = $table ;



    vprintheader("Created new SimConfig object $self");
	my $p = $pdb->GetPotential($pqr,$idx,$pots);
	my $nm = $pdb->GetAtomIdx($idx)->GetName();
	vprint("\tSetting potential diff of $nm to $p");
	$self->{POT} = $p;

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


sub GetPDB{
	my ($self) = @_ ; 
	return $self->{PDB}; 
}

sub ReachedFinalState{
	my ($self,$v) = @_ ; 
	my $diff = $v - $self->{POT} ;
	return 1 if($diff < -$SIGDIFFERENCEINPOT);
	return 0 ; 
}

sub IsProtonMoveValid{
	my ($self,$a,$b,$diff) = @_ ; 
	my $required = $DIFFFORMOVE ;

	my $A = $self->GetPDB()->GetAtomIdx($a);
	my $B = $self->GetPDB()->GetAtomIdx($b);

	## if target is basic, make pot required smaller
	my $resnameB = $B->GetResName();
	my $resnameA = $A->GetResName();
	my $nmA = $A->GetName();
	my $nmB = $B->GetName();

	my $aIsPolar = $self->{AACONFIG}->IsPolar($resnameA) ;
	my $aIsBasic = $self->{AACONFIG}->IsBasic($resnameA) ;
	my $aIsAcidic = $self->{AACONFIG}->IsAcidic($resnameA) ;
	my $aIsAmide = $self->{AACONFIG}->IsAmide($resnameA) ;

	my $bIsPolar = $self->{AACONFIG}->IsPolar($resnameB) ;
	my $bIsBasic = $self->{AACONFIG}->IsBasic($resnameB) ;
	my $bIsAcidic = $self->{AACONFIG}->IsAcidic($resnameB) ;
	my $bIsAmide = $self->{AACONFIG}->IsAmide($resnameB) ;

	return 0 if(!$aIsPolar);

    my $what = ""; 
	if($aIsAcidic && $bIsBasic){
		$what = "1a2b";
	}
	elsif($bIsAcidic && $aIsBasic){
		$what = "1b2a";
	}
	elsif($aIsAcidic && $bIsAcidic){
		$what = "1a2a";
	}
	elsif($aIsBasic && $bIsBasic){
		$what = "1b2b";
	}
	elsif($bIsBasic){
		$what = "1x2b";
	}
	elsif($bIsAmide){
		$what = "1x2m";
	}
	elsif($aIsBasic && $bIsPolar){
		$what = "1b2p";
	}
	if($what ne ""){
	     $required = $self->{MOVETABLE}->{$what} or die "$what is not there" ;
	}

	if($diff > $required){
		vprint("Allowed  for $a $b $nmA $nmB diff=$diff required=$required");
		return 1 ;
	}
    vprint("*Not* Allowed  for $a $b $nmA $nmB diff=$diff required=$required");
	return 0 ;
}


sub AdjustMove{
	my ($self,$simstate,$a,$b,$water)  = @_ ;
	my $pA = $simstate->GetPot($a) ;
	my $pB = $simstate->GetPot($b) ;

	my $a1 = $simstate->GetPDB()->GetAtomIdx($a);
	my $b1 = $simstate->GetPDB()->GetAtomIdx($b);
	my $n1 = $a1->GetName();
	my $n2 = $b1->GetName();

	my $DD = $a1->Distance($b1);
	my $idiff = $pA - $pB ;
	#my $del  = $idiff > 400 ? 300 : int($idiff/2) + 2; 
	my $half  = int($idiff/2) ;
	my $quarter  = int($half/2) ;
	my $del  = $idiff ;
	my $delminus  = 3*$quarter ; 
	my $delplus  = $quarter ;

	$simstate->SetPot($a, $simstate->GetPot($a) - $delminus );
	$simstate->SetPot($b, $simstate->GetPot($b) + $delplus );

	$pA = $simstate->GetPot($a) ;
	$pB = $simstate->GetPot($b) ;
	my $fdiff = $pA - $pB ;
	vprint("Adjusting move for $n1 to $n2 ( through water $water) - intial = $idiff final diff = ($pA - $pB) = $fdiff, dist = $DD");
}
