#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use IPC::Shm;

# MAKE A FEW VARIABLES

our $variable : Shm = { foo => { bar => 'bam' } };

# DETACH FROM THOSE VARIABLES

ok( untie $variable,			"untie \$variable" );
undef $variable;
ok( 1,					"undef \$variable" );

# GLOBAL CLEANUP

ok( IPC::Shm->cleanup,			"IPC::Shm->cleanup" );

