package IPC::Shm::Make;
use warnings;
use strict;
use Carp;
#
# makeshm( $scalar_variable_reference );
#
# If the referenced variable contains a plain scalar, nothing is done.
#
# If the referenced variable itself contains a reference, the target of that
# inner reference is tied into shared memory with its contents preserved.
#
# The inner reference is then replaced with a stand-in containing an
# identifier, which can be used to recover the original (now tied) target.
#
#
# my $tiedref = getback( $standin );
#
# Given the standin left by makeshm, returns a reference to the original
# (now tied into shared memory) data. It's up to the calling program to
# know whether it expects a scalar, array, or hash reference.
#
###############################################################################
# library dependencies

use base 'Exporter';
our @EXPORT = qw( makeshm getback );

use Data::Dumper;

###############################################################################
# lower level migration handlers

sub _makeshm_scalar {
	my ( $ref ) = @_;

	my $tmp = $$ref;
	my $obj = tie $$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	$$ref = $tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'SCALAR' );
	$obj->tiedref( $ref );

	return $obj->standin;
}

sub _makeshm_array {
	my ( $ref ) = @_;

	my @tmp = @$ref;
	my $obj = tie @$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	@$ref = @tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'ARRAY' );
	$obj->tiedref( $ref );

	return $obj->standin;
}

sub _makeshm_hash {
	my ( $ref ) = @_;

	my %tmp = %$ref;
	my $obj = tie %$ref, 'IPC::Shm::Tied';

	$obj->writelock;
	%$ref = %tmp;
	$obj->incref;
	$obj->unlock;

#	$obj->reftype( 'HASH' );
	$obj->tiedref( $ref );

	return $obj->standin;
}


###############################################################################
# migrate a variable into anonymous shared memory

sub makeshm {
	my ( $valueref ) = @_;

	my $reftype = ref( $$valueref );

	# pass plain scalars as-is
	return unless $reftype;

	# save a few dereferences
	my $refdata = $$valueref;

	if    ( $reftype eq 'SCALAR' ) {
		if ( my $obj = tied $$refdata ) {
			confess "Cannot store tied scalars in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			# replace with Ref reference
		}
		$$valueref = _makeshm_scalar( $refdata );
	}

	elsif ( $reftype eq 'ARRAY' ) {
		if ( my $obj = tied @$refdata ) {
			confess "Cannot store tied arrays in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			# replace with Ref reference
		}
		$$valueref = _makeshm_array( $refdata );
	}

	elsif ( $reftype eq 'HASH' ) {
		if ( my $obj = tied %$refdata ) {
			confess "Cannot store tied hashes in shared memory"
 				unless $obj->isa( 'IPC::Shm::Tied' );
			# replace with Ref reference
		}
		$$valueref = _makeshm_hash( $refdata );
	}

	else {
		confess "Incompatible reference";
	}

}


###############################################################################
# get back the (now shared) referenced datum

sub getback {
	my ( $standin ) = @_;

	my $share = IPC::Shm::Tied->restand( $standin )
		or confess "failed to restand standin";

	my $rv = $share->tiedref
		or carp "BUG: tiedref is empty";

	return $rv;
}


###############################################################################
###############################################################################
1;
