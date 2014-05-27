package IPC::Shm::Tied::HASH;
use warnings;
use strict;
use Carp;

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub _empty {
	return {};
}

sub TIEHASH {
	my ( $class, $share, @args ) = @_;

	# FIXME complain if store is missing

	$class->rebless( $share, @args );
	$share->reftype( 'HASH' );
	
	return $share;
}

sub FETCH {
	my ( $this, $key ) = @_;

	$this->readlock;
	$this->fetch;
	$this->unlock;

	my $rv = $this->vcache->{$key};

	return ref( $rv ) ? getback( $rv ) : $rv;	
}

sub STORE {
	my ( $this, $key, $value ) = @_;

	$this->writelock;
	$this->fetch;
	makeshm( \$value );

	my $vcache = $this->vcache;

	if ( $vcache->{$key} and ref( $vcache->{key} ) ) {
		my $share = $this->restand( $vcache->{key} );
		$share->decref;
	}

	$this->vcache->{$key} = $value;
	$this->flush;
	$this->unlock;

	return $value;
}

sub DELETE {
	my ( $this, $key ) = @_;
	my ( $temp );

	$this->writelock;
	$this->fetch;
	$temp = $this->vcache->{$key};
	delete $this->vcache->{$key};
	$this->flush;
	$this->unlock;

	return unless ref( $temp );

	my $share = $this->restand( $temp );
	$share->decref;

}

sub CLEAR {
	my ( $this ) = @_;

	my $rc = $this->writelock;
	$this->vcache( $this->_empty );
	$this->flush;
	$this->unlock if $rc;

}

sub EXISTS {
	my ( $this, $key ) = @_;

	$this->readlock;
	$this->fetch;
	$this->unlock;

	return exists $this->vcache->{$key};
}

sub FIRSTKEY {
	my ( $this ) = @_;

	$this->readlock;
	$this->fetch;
	$this->unlock;

	foreach my $key ( keys %{$this->vcache} ) {
		return $key;
	}

}

sub NEXTKEY {
	my ( $this, $lastkey ) = @_;
	my $found = 0;

	foreach my $key ( keys %{$this->vcache} ) {
		return $key if $found;	
		$found = 1 if $key eq $lastkey;
	}

	return undef;
}

sub SCALAR {
	my ( $this ) = @_;

	$this->readlock;
	$this->fetch;
	$this->unlock;

	return scalar %{$this->vcache};
}

sub UNTIE {
	my ( $this ) = @_;
	print "untying hash shared\n";
}


1;
