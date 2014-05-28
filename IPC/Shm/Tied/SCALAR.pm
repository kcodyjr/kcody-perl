package IPC::Shm::Tied::SCALAR;
use warnings;
use strict;
use Carp;

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub _empty {
	return \'';
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
	my $locked = $this->writelock;

	makeshm( \$value );
	$this->vcache( \$value );
	$this->flush;

	$this->unlock if $locked;
	return $value;
}

sub UNTIE {
	my ( $this ) = @_;
	print "untying scalar shared\n";	
}


1;
