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
# accessors

sub tiedref {
	my $this = shift;
	if ( my $newval = shift ) {
		return $this->{tiedref} = $newval;
	}
	return $this->{tiedref};
}

sub reftype {
	my $this = shift;
	if ( my $newval = shift ) {
		if ( my $vanon = $this->varanon ) {
			my $value = $IPC::Shm::ANONTYPE{$vanon};
			if ( $value and $value ne $newval ) {
				$IPC::Shm::ANONTYPE{$vanon} = $newval;
			}
		}
		return $this->{reftype} = $newval;
	}
	return $this->{reftype};
}


###############################################################################
# value cache, for the unserialized state

sub _empty {
	croak "Abstract _empty() invocation";
}

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
