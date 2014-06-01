package IPC::Shm::Tied::ARRAY;
use warnings;
use strict;
use Carp;

# Loaded from IPC::Shm::Tied, so don't reload it
use vars qw( @ISA );
@ISA = qw( IPC::Shm::Tied );

use IPC::Shm::Make;


sub EMPTY {
	return [];
}

sub TIEARRAY {
	my ( $class, $this ) = @_;

	return bless $this, $class;
}

sub FETCH {
	my ( $this, $index ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	my $rv = $this->vcache->[$index];

	return ref( $rv ) ? getback( $rv ) : $rv;
}

sub STORE {
	my ( $this, $index, $value ) = @_;

	makeshm( \$value );

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;
	my $oldval = $vcache->[$index];

	$vcache->[$index] = $value;
	$this->flush;

	$this->unlock if $locked;

	$this->discard( $oldval ) if ( $oldval and ref( $oldval ) );

	return $value;
}

sub FETCHSIZE {
	my ( $this ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return scalar @{$this->vcache};
}

sub STORESIZE {
	my ( $this, $newcount ) = @_;

	my $oldcount = $this->FETCHSIZE;

	$this->writelock;

	if ( $newcount > $oldcount ) {
		for ( my $i = $oldcount; $i < $newcount; $i++ ) {
			$this->PUSH( undef );
		}
	}

	elsif ( $newcount < $oldcount ) {
		for ( my $i = $oldcount; $i > $newcount; $i-- ) {
			$this->POP;
		}
	}

	$this->unlock;

	return;
}

sub EXTEND {
	my ( $this, $count ) = @_;

	$this->STORESIZE( $count );

	return;
}

sub EXISTS {
	my ( $this, $index ) = @_;

	my $locked = $this->readlock;
	$this->fetch;
	$this->unlock if $locked;

	return exists $this->vcache->[$index];
}

sub DELETE {
	my ( $this, $index ) = @_;

	$this->STORE( $index, undef );

	return;
}

sub CLEAR {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	$this->vcache( $this->EMPTY );
	$this->flush;

	$this->unlock if $locked;

	foreach my $oldval ( @{$vcache} ) {
		$this->discard( $oldval ) if ( $oldval and ref( $oldval ) );
	}

	return;
}

sub PUSH {
	my ( $this, @list ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	foreach my $newval ( @list ) {
		makeshm( \$newval );
		push @{$vcache}, $newval;
	}

	$this->flush;

	$this->unlock if $locked;

	return;
}

sub POP {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	unless ( scalar @{$vcache} ) {
		$this->unlock if $locked;
		return undef;
	}

	my $rv = pop @{$vcache};
	$this->flush;

	$this->unlock if $locked;

	# FIXME leaves a dangling reference

	return ref( $rv ) ? getback( $rv ) : $rv;
}

sub SHIFT {
	my ( $this ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	unless ( scalar @{$vcache} ) {
		$this->unlock if $locked;
		return undef;
	}

	my $rv = shift @{$vcache};
	$this->flush;

	$this->unlock if $locked;

	# FIXME leaves a dangling reference

	return $rv;
}

sub UNSHIFT {
	my ( $this, @list ) = @_;

	my $locked = $this->writelock;

	$this->fetch;
	my $vcache = $this->vcache;

	foreach my $newval ( @list ) {
		makeshm( \$newval );
		unshift @{$vcache}, $newval;
	}

	$this->flush;

	$this->unlock if $locked;

	return;
}

# better this doesn't exist, until i get around to implementing it
#sub SPLICE {
#	my ( $this, $offset, $length, @list ) = @_;
#
#}


1;
