#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;

use IPC::Shm;
my ( $obj );

# CLEAN UP SCALARS

our $variable : Shm;

ok( $obj = tied( $variable ), 		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

# CLEAN UP ARRAYS

our @variable : Shm;

ok( $obj = tied( @variable ),		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

# CLEAN UP HASHES

our %variable : Shm;

ok( $obj = tied( %variable ),		"retrieving object" );
ok( $obj->remove, 			"removing segment" );

