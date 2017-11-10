package Linux::InitFS::Feature::Core;
use warnings;
use strict;

use base 'Linux::InitFS::Feature';

my @BINS = qw( /bin/busybox );
my @TERM = qw( ansi dumb linux vt100 vt102 vt200 vt220 vt52 );
my @MNTS = qw( /mnt/rootfs /sys /proc );
my @DIRS = qw( /run /tmp );

my %DEVS = qw();
my %LINK = qw();


{ # private lexicals begin
my $mode = undef;

sub devtmpfs_mode {
	my ( $this ) = @_;

	return $mode if defined $mode;

	return $mode = 'auto' if $this->is_enabled( 'DEVTMPFS_MOUNT' );
	return $mode = 'on'   if $this->is_enabled( 'DEVTMPFS' );
	return $mode = '';
}

} # private lexicals end


sub sense_dev_mode {
	my ( $this ) = @_;

	my $mode = $this->devtmpfs_mode();

	if ( $mode eq 'auto' ) {
		push @MNTS, '/dev';
		return;
	}

	# need initial console

	%DEVS = (
		null	=> [qw( c 1 3 0666 0 0 )],
		zero	=> [qw( c 1 5 0666 0 0 )],
		full	=> [qw( c 1 7 0666 0 0 )],
		random	=> [qw( c 1 8 0666 0 0 )],
		urandom	=> [qw( c 1 9 0666 0 0 )],
		tty0	=> [qw( c 4 0 0620 0 0 )],
		tty1	=> [qw( c 4 1 0620 0 0 )],
		tty2	=> [qw( c 4 2 0620 0 0 )],
		tty	=> [qw( c 5 0 0620 0 0 )],
		console	=> [qw( c 5 1 0666 0 0 )],
		ptmx	=> [qw( c 5 2 0666 0 0 )],
	);

	%LINK = (
		fd	=> '/proc/self/fd',
		stdin	=> '/proc/self/fd/0',
		stdout	=> '/proc/self/fd/1',
		stderr	=> '/proc/self/fd/2'
	);

	return if $mode;

	# need full contents

	return;
}


sub ENABLE {
	my ( $this ) = @_;

	$this->sense_dev_mode();

	# root's home dir
	Linux::InitFS::Entry->new_dir( '/root', mode => 0700 );

	# standard directories
	Linux::InitFS::Entry->new_dir( $_ ) for @DIRS;

	# standard mount points
	Linux::InitFS::Entry->new_mnt_point( $_ ) for @MNTS;

	# requested programs
	Linux::InitFS::Entry->new_host_prog( $_ ) for @BINS;

	# terminal type info
	Linux::InitFS::Entry->new_term_type( $_ ) for @TERM;

	# device nodes
	for my $dev ( keys %DEVS ) {
		my ( $dtype, $major, $minor, $mode, $owner, $group ) = @{$DEVS{$dev}};

		$dev  = '/dev/' . $dev;
		$mode = oct( $mode );

		Linux::InitFS::Entry->new_nod( $dev, $dtype, $major, $minor,
			mode  => $mode,  owner => $owner, group => $group );

	}

	# symlinks
	for my $link ( keys %LINK ) {
		my $full = '/dev/' . $link;
		Linux::InitFS::Entry->new_slink( $full, $LINK{$link} );
	}

	# init script
	Linux::InitFS::Entry->new_prog( '/init', '/usr/src/initfs/init' );

}


1;
# vim: ts=8
