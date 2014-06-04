#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;

use IPC::Shm;

# MAKE A FEW VARIABLES

our $variable : Shm = { foo => { bar => 'bam' } };

# GLOBAL CLEANUP

ok( IPC::Shm->cleanup,			"IPC::Shm->cleanup" );

