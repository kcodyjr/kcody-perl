package IPC::Shm::Tied::ARRAY;
use warnings;
use strict;
use Carp;

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub _empty {
	return [];
}

sub TIEARRAY {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this, $index ) = @_;

	$this->readlock;
	$this->fetch;
	$this->unlock;

	return $this->vcache->[$index];
}

sub STORE {
	my ( $this, $index, $value ) = @_;

	$this->writelock;
	$this->fetch;
	$this->vcache->[$index] = $value;
	$this->flush;
	$this->unlock;

	return $value;
}

sub FETCHSIZE {
	my ( $this ) = @_;
}

sub STORESIZE {
	my ( $this, $count ) = @_;
}

sub EXTEND {
	my ( $this, $count ) = @_;
}

sub EXISTS {
	my ( $this, $key ) = @_;
}

sub DELETE {
	my ( $this, $key ) = @_;
}

sub CLEAR {
	my ( $this ) = @_;

	my $rc = $this->writelock;
	$this->vcache( $this->_empty );
	$this->flush;
	$this->unlock if $rc;

}

sub PUSH {
	my ( $this, @list ) = @_;

	$this->writelock;
	$this->fetch;

	# FIXME: go element by element so STORE can intercept references
	push @{$this->vcache}, @list;

	$this->flush;
	$this->unlock;

}

sub POP {
	my ( $this ) = @_;

	$this->writelock;
	$this->fetch;

	unless ( scalar( @{$this->vcache} ) ) {
		$this->unlock;
		return;
	}

	my $rv = pop @{$this->vcache};
	$this->flush;
	$this->unlock;

	return $rv;
}

sub SHIFT {
	my ( $this ) = @_;

	$this->writelock;
	$this->fetch;

	unless ( scalar( @{$this->vcache} ) ) {
		$this->unlock;
		return;
	}

	my $rv = shift @{$this->vcache};
	$this->flush;
	$this->unlock;

	return $rv;
}

sub UNSHIFT {
	my ( $this, @list ) = @_;

	$this->writelock;
	$this->fetch;

	# FIXME: go element by element so STORE can intercept references
	unshift @{$this->vcache}, @list;

	$this->flush;
	$this->unlock;

}

sub SPLICE {
	my ( $this, $offset, $length, @list ) = @_;

}

sub UNTIE {
	my ( $this ) = @_;
}


1;
