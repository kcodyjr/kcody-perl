#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 9;

use IPC::Shm;

# verify scalar can contain shared references to named segments

our %pkgvar : Shm = ( foo => 'bar' );
my  $lexvar : Shm;

is( $pkgvar{foo}, 'bar',		"\$pkgvar{foo} == 'bar'" );

ok( $lexvar = \%pkgvar, 		"\$lexvar = \\\%pkgvar" );
is( $lexvar->{foo}, 'bar',		"\$lexvar->{foo} == 'bar'" );

is( $lexvar->{foo} = 123, 123,		"\$lexvar->{foo} = 123" );
is( ++$pkgvar{foo}, 124,		"++\$pkgvar{foo} == 124" );
is( $lexvar->{foo}, 124,		"\$lexvar->{foo} == 124" );

is( scalar keys %$lexvar, 1,		"scalar keys \%\$lexvar == 1" );
undef %pkgvar;
ok( 1,					"undef %pkgvar" );
is( scalar keys %$lexvar, 0,		"scalar keys \%\$lexvar == 0" );

