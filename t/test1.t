#!/usr/bin/perl
use warnings;
use strict;
use lib '..';

use IPC::Shm;

use Test::More tests => 9;

my ( $obj, $tmp );

our $variable : Shm;

ok( $obj = tied( $variable ), "retrieving object" );

$obj->CLEAR;

is( $variable, undef, "variable contains undef" );

ok( $variable = 'onetwothree', "assigning string value" );

is( $variable, 'onetwothree', "\$variable == 'onetwothree'" );

ok( $variable = { foo => 'bar' }, "assigning anonymous hash" );

is( $variable->{foo}, "bar", "\$variable->{foo} == 'bar'" );

$tmp = { foo => 'bam' };

ok( $variable = $tmp );

is( $variable->{foo}, 'bam', "\$variable->{foo} == 'bam'" );

$tmp->{foo} = 'bat';

is( $variable->{foo}, 'bat', "\$variable->{foo} == 'bat'" );

