#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 10;

use IPC::Shm;

# VERIFY SCALARS

our $variable : Shm;
my ( $tmp );

is( $variable->{foo}, 'bar',		"\$variable->{foo} == 'bar'" );

ok( $tmp = $variable,			"\$tmp = \$variable" );
is( $tmp, $variable,			"\$tmp == \$variable" );

is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

undef $variable;
ok( 1,					"undef \$variable" );
is( $variable, undef,			"\$variable == undef" );

is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

undef $tmp;
ok( 1,					"undef \$tmp" );
is( $tmp, undef,			"\$tmp == undef" );

# VERIFY LEXICALS

my $lexical : Shm;

is( $lexical, undef,			"\$lexical == undef" );

# VERIFY ARRAYS

#our @variable : Shm;

# VERIFY HASHES

#our %variable : Shm;


