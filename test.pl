# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use IPC::Shm::Simple;
use Fcntl qw( :flock );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# If a semaphore or shared memory segment already uses this
# key, all tests will fail
$KEY = 192; 

$num = 1;

# Test object construction
$num++;
my $share = IPC::Shm::Simple->create($KEY, 100, 0660);
print (defined $share ? "ok $num\n" : "not ok $num\n");

die unless $share;

# Store value
$num++;
my $result = $share->store('maurice');
print ("ok $num\n");

# Retrieve value
$num++;
my $result = $share->fetch;
print ($result eq 'maurice' ? "ok $num\n" : "not ok $num\n");

# Fragmented store
$num++;
my $result = $share->store( "X" x 10000 );
print ("ok $num\n");

# Check number of segments
$num++;
print ($share->nsegments == 3 ? "ok $num\n" : "not ok $num\n");

# Fragmented fetch
$num++;
my $result = $share->fetch;
print ($result eq 'X' x 10000 ? "ok $num\n" : "not ok $num\n");


$num++;
$share->store( 0 );
$share->lock(LOCK_UN);
my $pid = fork;
defined $pid or die $!;
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
  for(1..1000) {
    $share->lock( LOCK_EX ) or die $!;
    $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->lock( LOCK_UN ) or die $!;
  } 
  wait;

  $share->lock( LOCK_EX );
  $val = $share->fetch;
  print ($val == 2000 ? "ok $num\n" : "not ok $num\n");
  $share->lock( LOCK_UN );
}

# mark share for deletion
$num++;
my $result = $share->remove();
print (defined $result ? "ok $num\n" : "not ok $num\n");

# cause undefine
$num++;
my $result = undef $share;
print ("ok $num\n");

