package IPC::Shm::Tied;
use warnings;
use strict;
use Carp;

use base 'IPC::Shm::Segment';

use IPC::Shm::Tied::HASH;
use IPC::Shm::Tied::ARRAY;
use IPC::Shm::Tied::SCALAR;

use Data::Dumper;
use Storable qw( freeze thaw );


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
# special attribute accessors

sub tiedref {
	my $this = shift;

	return $this->{tiedref}
		unless my $newval = shift;

	confess "expecting a reference"
		unless my $reftype = ref( $newval );

	$this->reftype( $reftype );

	return $this->{tiedref} = $newval;
}

sub reftype {
	my $this = shift;

	return $this->{reftype} unless my $newval = shift;

	# we only care about anonymous segments
	return $this->{reftype} unless my $vanon = $this->varanon;

	my $value = $IPC::Shm::ANONTYPE{$vanon};

	# and we want to avoid unnecessary shared memory writes
	unless ( $value and $value eq $newval ) {
		$IPC::Shm::ANONTYPE{$vanon} = $this->{reftype} =  $newval;
	}

	return $this->{reftype};
}


###############################################################################
# abstract empty value representation

sub _empty {
	croak "Abstract _empty() invocation";
}


###############################################################################
# value cache, for the unserialized in-memory state

sub vcache {
	my $this = shift;

	if ( my $create = shift ) {
		return $this->{vcache} = $create;
	}

	unless ( defined $this->{vcache} ) {
		$this->{vcache} = $this->_empty;
	}

	return $this->{vcache};
}


###############################################################################
# serialize and deserialize routines

# reads from scache, writes to vcache
# called by IPC::Shm::Simple::fetch
sub _fresh {
	my ( $this ) = @_;

	print "deserializing ", $this->serial, "\n";
	my $thawed = eval { thaw( ${$this->scache} ) };
	$this->vcache( $thawed ? $thawed : $this->_empty );

	print Dumper( $this->vcache ), "\n";

}

# reads from vcache, calls store
sub flush {
	my ( $this ) = @_;

	print "serializing ", $this->serial + 1, "\n";
	print Dumper( $this->vcache ), "\n";

	$this->store( freeze( $this->vcache ) );
	
}


###############################################################################
###############################################################################
1;
