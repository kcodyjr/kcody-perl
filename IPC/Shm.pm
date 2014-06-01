package IPC::Shm;
use warnings;
use strict;
use Carp;
#
# Attribute interface for shared memory variables.
#
# This is the recommended way to put variables in shared memory.
#
# Synopsis:
#
# use IPC::Shm;
# our $VARIABLE : shm;
#
# And then just use it like you would any other variable.
# Scalars, hashes, and arrays are supported.
# Implemented using tie().
#
###############################################################################
# library dependencies

use Attribute::Handlers;

our $VERSION = '0.2';


###############################################################################
# argument normalizers

sub _attrtie_normalize_data($) {
	my ( $data ) = @_;

	if ( not defined $data ) {
		$data = [];
	}

	elsif ( ref( $data ) ne 'ARRAY' ) {
		$data = [ $data ];
	}

	return $data;
}

sub _attrtie_normalize_symbol($$) {
	my ( $sym, $type ) = @_;

	return $sym if $sym eq 'LEXICAL';

	$sym = *$sym;

	my $tmp = $type eq 'HASH' ? '%'
		: $type eq 'ARRAY' ? '@'
		: $type eq 'SCALAR' ? '$'
		: '*';

	$sym =~ s/^\*/$tmp/;

	return $sym;
}


###############################################################################
# sanity checks

sub _attrtie_check_ref_sanity($) {
	my ( $ref ) = @_;

	my $rv = ref( $ref )
		or confess "BUG:\$_[2] is not a reference";

	if ( $rv eq 'CODE' ) {
		confess "Subroutines cannot be placed in shared memory";
	}

	if ( $rv eq 'HANDLE' ) {
		confess "Handles cannot be placed in shared memory";
	}

	return $rv if $rv eq 'HASH';
	return $rv if $rv eq 'ARRAY';
	return $rv if $rv eq 'SCALAR';

	confess "Unknown reference type '$rv'";
}


###############################################################################
# shared memory attribute handler

sub UNIVERSAL::shm : ATTR(ANY) {
	my ( $pkg, $sym, $ref, $attr, $data, $phase ) = @_;
	my ( $type, $obj );

	$data = _attrtie_normalize_data( $data );
	$type = _attrtie_check_ref_sanity( $ref );
	$sym  = _attrtie_normalize_symbol( $sym, $type );

	my $segment = $sym eq 'LEXICAL'
		? IPC::Shm::Segment->lexical( $ref )
		: IPC::Shm::Segment->named( $sym )
		or confess "Unable to find shm store";

	if    ( $type eq 'HASH' ) {
		$obj = tie %$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

	elsif ( $type eq 'ARRAY' ) {
		$obj = tie @$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

	elsif ( $type eq 'SCALAR' ) {
		$obj = tie $$ref, 'IPC::Shm::Tied', $segment, @$data;
	}

#	$obj->reftype( $type );
	$obj->tiedref( $ref );

	if ( $sym eq '%IPC::Shm::NAMEVARS' ) {
		unless ( $IPC::Shm::NAMEVARS{$sym} ) {
			$IPC::Shm::NAMEVARS{$sym} = $segment->shmid;
		}
	}

}


###############################################################################
# late library dependencies - after the above compiles

use IPC::Shm::Segment;
use IPC::Shm::Tied;


###############################################################################
# shared memory variables used by this package

our %NAMEVARS : shm;
our %ANONVARS : shm;
our %ANONTYPE : shm;


###############################################################################
###############################################################################
1;
