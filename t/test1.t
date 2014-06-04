#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 17;

use IPC::Shm;

# EXERCISE SCALARS

our $variable : Shm;
my ( $obj, $tmp );

ok( $obj = tied( $variable ),		"retrieving object" );
ok( $obj->CLEAR,			"clearing \$variable" );
is( $variable, undef,			"\$variable == undef" );

ok( $variable = 'onetwothree',		"\$variable = 'onetwothree'" );
is( $variable, 'onetwothree',		"\$variable == 'onetwothree'" );

ok( $variable = { foo => 'bar' },	"\$variable = { foo => 'bar' }" );
is( $variable->{foo}, "bar",		"\$variable->{foo} == 'bar'" );

ok( $tmp = { foo => 'bam' },		"\$tmp = { foo => 'bam' }" );
ok( $variable = $tmp,			"\$variable = \$tmp" );
is( $variable->{foo}, 'bam',		"\$variable->{foo} == 'bam'" );

ok( $tmp->{foo} = 'bat',		"\$tmp->{foo} = 'bat'" );
is( $variable->{foo}, 'bat',		"\$variable->{foo} == 'bat'" );

ok( $variable->{foo} = 'bar',		"\$variable->{foo} = 'bar'" );
is( $tmp->{foo}, 'bar',			"\$tmp->{foo} == 'bar'" );

# EXERCISE LEXICALS

my $lexical : Shm;

is( $lexical, undef,			"\$lexical == undef" );
ok( $lexical = 'fourfivesix',		"\$lexical = 'fourfivesix'" );
is( $lexical, 'fourfivesix',		"\$lexical == 'fourfivesix'" );


# EXERCISE ARRAYS

#our @variable : Shm;

# EXERCISE HASHES

#our %variable : Shm;


