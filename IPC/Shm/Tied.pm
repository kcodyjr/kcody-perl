package IPC::Shm::Tied;
use warnings;
use strict;
use Carp;

use base 'IPC::Shm::Segment';

use IPC::Shm::Tied::HASH;
use IPC::Shm::Tied::ARRAY;
use IPC::Shm::Tied::SCALAR;

use Scalar::Util qw( weaken );
use Storable	 qw( freeze thaw );


###############################################################################
# tie constructors

sub TIEHASH {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::HASH->TIEHASH( @_ );
}

sub TIEARRAY {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::ARRAY->TIEARRAY( @_ );
}

sub TIESCALAR {
	shift; # discard class we were called as
	$_[0] ||= IPC::Shm::Segment->anonymous;
	return IPC::Shm::Tied::SCALAR->TIESCALAR( @_ );
}


###############################################################################
# reconstructor - dynamically create a tied reference

sub retie {
	my ( $this ) = @_;
	my ( $rv );

	my $type = $this->vartype;

	if    ( $type eq 'HASH' ) {
		tie my %tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \%tmp );
	}

	elsif ( $type eq 'ARRAY' ) {
		tie my @tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \@tmp );
	}

	elsif ( $type eq 'SCALAR' ) {
		tie my $tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( $rv = \$tmp );
	}

	else {
		confess "unknown reference type";
	}

	return $rv;
}


###############################################################################
# store the tied reference so we can get it back from the object later

{ # BEGIN private lexicals
my %TiedRef = ();

sub tiedref_clean {
	delete $TiedRef{shift->{shmid}};
	return;
}

sub tiedref {
	my $this = shift;

	my $shmid = $this->{shmid};

	if ( my $newval = shift ) {

		unless ( defined $newval ) {
			delete $TiedRef{$shmid};
			return;
		}

		confess __PACKAGE__ . "->tiedref() expects a reference"
			unless my $reftype = ref( $newval );

		$this->reftype( $reftype );

		$TiedRef{$shmid} = $newval;
		weaken $TiedRef{$shmid};

		return $newval;
	}

	# keep a temporary reference to the end of this sub
	my $tv = $this->retie unless defined $TiedRef{$shmid};

	return $TiedRef{$shmid};
}

} # END private lexicals

sub reftype {
	my $this = shift;

	return $this->{reftype} unless my $newval = shift;

	# avoid unnecessary shared memory access
	if ( $this->{reftype} ) {
		return $newval if $newval eq $this->{reftype};
	}

	# we only care about anonymous segments
	return $this->{reftype} unless my $vanon = $this->varanon;

	my $value = $IPC::Shm::ANONTYPE{$vanon};

	# and we want to avoid unnecessary shared memory writes
	unless ( $value and $value eq $newval ) {
		$IPC::Shm::ANONTYPE{$vanon} =  $newval;
	}

	return $this->{reftype} = $newval;
}


###############################################################################
# abstract empty value representation

sub EMPTY {
	croak "Abstract EMPTY() invocation";
}


###############################################################################
# value cache, for the unserialized in-memory state

{ # BEGIN private lexicals
my %ValCache = ();

sub vcache {
	my $this = shift;

	my $shmid = $this->{shmid};

	if ( my $newval = shift ) {
		return $ValCache{$shmid} = $newval;
	}

	unless ( defined $ValCache{$shmid} ) {
		$ValCache{$shmid} = $this->EMPTY;
	}

	return $ValCache{$shmid};
}

sub vcache_clean {
	my ( $this ) = @_;

	delete $ValCache{$this->{shmid}};

	return;
}

} # END private lexicals

sub DETACH {
	my ( $this ) = @_;

	$this->vcache_clean;
	$this->tiedref_clean;
	$this->SUPER::DETACH;

	return;
}


###############################################################################
# serialize and deserialize routines

# reads from scache, writes to vcache
# called by IPC::Shm::Simple::fetch
sub FRESH {
	my ( $this ) = @_;

	my $thawed = eval { thaw( ${$this->scache} ) };
	$this->vcache( $thawed ? $thawed : $this->EMPTY );

}

# reads from vcache, calls store
sub flush {
	my ( $this ) = @_;

	$this->store( freeze( $this->vcache ) );
	
}


###############################################################################
###############################################################################
1;
