#!/usr/bin/perl
use warnings;
use strict;
use lib '..';

use IPC::Shm;
use Data::Dumper;

#my $variable : shm = "onetwothree";
our $variable : shm;

print "variable0: ", $variable, "\n";
print "variable0: ", Dumper( $variable ), "\n";

print "changing variable\n";

$variable = {};

print "variableZ: ", $variable, "\n";

$variable = 'onetwothree';

print "variable1: ", $variable, "\n";

$variable = 'fourfivesix';

print "variable2: ", $variable, "\n";

my $testing = { foo => 'bar' };

$variable = $testing;
print "done setting\n";
print "variable3: ", $variable->{foo}, "\n";
print "variable3: ", Dumper( $variable );

$variable->{foo} = 'bam';

print "variable4: ", $variable->{foo}, "\n";
print "variable4: ", Dumper( $variable );

#$testing->{foo} = { bar => 'bat' };
$testing->{foo} = 'bat';

print "variable5: ", $variable->{foo}, "\n";
print "variable5: ", Dumper( $variable );

print "--- done testing\n";
