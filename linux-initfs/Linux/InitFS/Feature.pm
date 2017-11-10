package Linux::InitFS::Feature;
use warnings;
use strict;

use Linux::InitFS::Spec;


sub is_enabled($) {
	my ( $this, $feature ) = @_;

	$feature ||= $this;

	return Linux::InitFS::Kernel::feature_enabled( $feature );
}


sub locate_host_prog($) {
	my ( $prog ) = @_;

	my @path = split /:/, $ENV{PATH};

	unshift @path, '/sbin', '/usr/sbin' unless grep /sbin/, @path;

	while ( my $path = shift @path ) {
		my $full = $path . '/' . $prog;
		return $full if -x $full;
	}

	return;
}


sub locate_init_file($$) {
	my ( $name, $file ) = @_;

	return join( '/', '/usr/share/initfs/files', $name, $file );
}


sub translate_args(@) {
	my ( @args ) = @_;
	my ( %rv, $arg );

	$rv{mode} = oct $arg if $arg = shift @args;
	$rv{owner} = $arg    if $arg = shift @args;
	$rv{group} = $arg    if $arg = shift @args;

	return %rv;
}


sub enable_feature_item($@) {
	my ( $name, $kind, $path, @args ) = @_;
	my %more;

	if ( $kind eq 'device' ) {
		my $dtype = shift @args;
		my $major = shift @args;
		my $minor = shift @args;
		%more = translate_args @args;
		$path = '/dev/' . $path;
		Linux::InitFS::Entry->new_nod( $path, $dtype, $major, $minor, %more );
	}

	elsif ( $kind eq 'termtype' ) {
		Linux::InitFS::Entry->new_term_type( $path );
	}

	elsif ( $kind eq 'symlink' ) {
		my $link = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_slink( $path, $link, %more );
	}

	elsif ( $kind eq 'directory' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_dir( $path, %more );
	}

	elsif ( $kind eq 'mountpoint' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_mnt_point( $path, %more );
	}

	elsif ( $kind eq 'host_file' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_host_file( $path, %more );
	}

	elsif ( $kind eq 'host_program' ) {
		%more = translate_args @args;
		$path = locate_host_prog $path or return;
		Linux::InitFS::Entry->new_host_prog( $path, %more );
	}

	elsif ( $kind eq 'init_file' ) {
		my $from = locate_init_file $name, $path;
		$path = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_file( $path, $from, %more );
	}

	elsif ( $kind eq 'init_program' ) {
		my $from = locate_init_file $name, $path;
		$path = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_prog( $path, $from, %more );
	}

	else {
		warn "Unknown directive $kind\n";
	}

}


sub enable_feature($) {
	my ( $name ) = @_;

	my $spec = Linux::InitFS::Spec->new( $name )
		or return;

	enable_feature_item( $name, @$_ ) for @$spec;

}


sub enable_features() {

	enable_feature 'core';
	enable_feature 'rescue';
	enable_feature 'vendor';

	if ( is_enabled 'DEVTMPFS_MOUNT' ) {
		enable_feature 'devtmpfs-mount';
	}

	elsif ( is_enabled 'DEVTMPFS' ) {
		enable_feature 'devtmpfs';
	}

	else {
		# FIXME implement
	}

	# FIXME move into a spec file somewhere

	enable_feature 'MD'   if is_enabled 'BLK_DEV_MD';
	enable_feature 'LVM'  if is_enabled 'BLK_DEV_DM';
	enable_feature 'LUKS' if is_enabled 'DM_CRYPT';

	return 1;
}


1;
