# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use warnings;
use strict;

use Test::More tests => 17;

use Fcntl qw( :flock );
use IPC::Shm::Simple;

use vars qw( $KEY $pid $val );

# If a semaphore or shared memory segment already uses this
# key, all tests will fail
$KEY = 192; 

my ( $share, $result );

# Test object construction
ok( $share = IPC::Shm::Simple->create($KEY, 256, 0660), 'create( $KEY )' );

# remove it
ok( $share ? $share->remove() : 1, 'remove()' );

# create a new anony
ok( $share = IPC::Shm::Simple->create(), 'create()' );

# continue testing only if we actually have a segment
die $! unless $share;

# Store value
ok( $share->store('maurice'), 'store( "maurice" )' );

# Retrieve value
is( $share->fetch, 'maurice', 'fetch()' );

# Fragmented store
ok( $share->store( "X" x 10000 ), 'store( "X" x 10000 )');

# Check number of segments
is( $share->nsegments, 3, 'nsegments == 3' );

# check actual size
is( $share->length, 10000, 'length == 10000' );

# check serial number
is( $share->serial, 2, 'serial == 2' );

# Fragmented fetch
is( $share->fetch, 'X' x 10000, 'fetch()' );

# set back to a zero value
ok( $share->store( 0 ), 'store( 0 )' );

# verify we're back to one segment
is( $share->nsegments, 1, 'nsegments == 1' );

# unlock the segment prior to fork
ok( $share->lock(LOCK_UN), 'lock( LOCK_UN )' );

defined( $pid = fork ) or die $!;

if ($pid == 0) {
#  $share->destroy( 0 );
  for(1..1000) {
    $share->lock( LOCK_EX ) or die $!;
    $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->lock( LOCK_UN ) or die $!;
  }
  exit;
} else {
  ok( defined $pid, 'fork()' );
  for(1..1000) {
    $share->lock( LOCK_EX ) or die $!;
    $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->lock( LOCK_UN ) or die $!;
  } 
  wait;

  $share->lock( LOCK_EX );
  is( $share->fetch, 2000, 'fetch() == 2000' );
  $share->lock( LOCK_UN );
}

# mark share for deletion
ok( $share->remove(), 'remove()' );

# cause undefine - test returns true to prove the script is still running
undef $share;
ok( 1, 'undef' );

