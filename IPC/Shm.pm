package IPC::Shm;
use warnings;
use strict;
use Carp;
#
# Copyright (c) 2014 by Kevin Cody-Little <kcody@cpan.org>
#
# This code may be modified or redistributed under the terms
# of either the Artistic or GNU General Public licenses, at
# the modifier or redistributor's discretion.
#

=head1 NAME

IPC::Shm - Easily Store Variables in SysV Shared Memory

=head1 SYNOPSIS

 use IPC::Shm;
 our %variable : shm;

Then, just use it like any other variable.

=head1 EXPLANATION

The "shm" variable attribute confers two properties:

=over

=item 1. The variable will persist beyond the program's end.

=item 2. All simultaneous processes will see the same value.

=back

Scalars, hashes, and arrays are supported.

Storing references is legal; however, the target of the reference will itself
be moved into its own shared memory segment with contents preserved.

Blessed references might work but are untested.

=head1 LEXICALS

Lexical variables are treated as anonymous, and are supported. They will only
outlive the process if another shared variable contains a reference to it.

=head1 CURRENT STATUS

This is alpha code. There are no doubt many bugs.

In particular, the multiple simultaneous process use case has not been tested.

=cut

###############################################################################
# library dependencies

use Attribute::Handlers;

our $VERSION = '0.30';


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
		? IPC::Shm::Segment->anonymous
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
