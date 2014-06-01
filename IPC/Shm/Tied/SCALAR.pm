package IPC::Shm::Tied::SCALAR;
use warnings;
use strict;
use Carp;

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub EMPTY {
	return \undef;
}

sub TIESCALAR {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this ) = @_;

	my $locked = $this->readlock;

	$this->fetch;

	$this->unlock if $locked;

	my $rv = ${$this->vcache};

	return ref( $rv ) ? getback( $rv ) : $rv;
}

sub STORE {
	my ( $this, $value ) = @_;

	makeshm( \$value );

	my $locked = $this->writelock;

	$this->fetch;
	my $oldval = ${$this->vcache};

	$this->vcache( \$value );
	$this->flush;

	$this->unlock if $locked;

	if ( ref( $oldval ) ) {
		$this->discard( $oldval );
	}

	return $value;
}

sub CLEAR {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $oldval = ${$this->vcache};

	$this->vcache( $this->EMPTY );
	$this->flush;

	$this->unlock if $locked;

	$this->discard( $oldval ) if ( $oldval and ref( $oldval ) );

}


1;
