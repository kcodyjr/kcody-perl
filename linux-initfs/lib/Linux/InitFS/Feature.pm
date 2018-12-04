package Linux::InitFS::Feature;
use warnings;
use strict;

use File::ShareDir;
use Linux::InitFS::Spec;

my $BASE = File::ShareDir::dist_dir( 'Linux-InitFS' );


###############################################################################
# helper functions

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

	return join( '/', $BASE, 'files', $name, $file );
}


sub translate_args(@) {
	my ( @args ) = @_;
	my ( %rv, $arg );

	$rv{mode} = oct $arg if $arg = shift @args;
	$rv{owner} = $arg    if $arg = shift @args;
	$rv{group} = $arg    if $arg = shift @args;

	return %rv;
}


###############################################################################
# add entries to $ctx for each file/symlink/devnode/etc in the given feature

sub enable_feature($$$);

sub enable_feature_item($$$@) {
	my ( $class, $ctx, $name, $kind, $path, @args ) = @_;
	my %more;

	if ( $kind eq 'device' ) {
		my $dtype = shift @args;
		my $major = shift @args;
		my $minor = shift @args;
		%more = translate_args @args;
		$path = '/dev/' . $path;
		Linux::InitFS::Entry->new_nod( $ctx, $path, $dtype, $major, $minor, %more );
	}

	elsif ( $kind eq 'termtype' ) {
		Linux::InitFS::Entry->new_term_type( $ctx, $path );
	}

	elsif ( $kind eq 'symlink' ) {
		my $link = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_slink( $ctx, $path, $link, %more );
	}

	elsif ( $kind eq 'directory' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_dir( $ctx, $path, %more );
	}

	elsif ( $kind eq 'mountpoint' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_mnt_point( $ctx, $path, %more );
	}

	elsif ( $kind eq 'host_file' ) {
		%more = translate_args @args;
		Linux::InitFS::Entry->new_host_file( $ctx, $path, %more );
	}

	elsif ( $kind eq 'host_program' ) {
		%more = translate_args @args;
		$path = locate_host_prog $path or return;
		Linux::InitFS::Entry->new_host_prog( $ctx, $path, %more );
	}

	elsif ( $kind eq 'init_file' ) {
		my $from = locate_init_file $name, $path;
		$path = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_file( $ctx, $path, $from, %more );
	}

	elsif ( $kind eq 'init_program' ) {
		my $from = locate_init_file $name, $path;
		$path = shift @args;
		%more = translate_args @args;
		Linux::InitFS::Entry->new_prog( $ctx, $path, $from, %more );
	}

	elsif ( $kind eq 'requires' ) {
		enable_feature $class, $ctx, $path;
	}

	else {
		warn "Unknown directive $kind\n";
	}

}


sub enable_feature($$$) {
	my ( $class, $ctx, $name ) = @_;

	my $spec = Linux::InitFS::Spec->new( $name )
		or return;

	enable_feature_item( $class, $ctx, $name, @$_ ) for @$spec;

}


###############################################################################
# feature-wise truth tester

sub is_enabled($$) {
	my ( $cfg, $feature ) = @_;
	my $rv;

	if ( $feature =~ /:/ ) {
		my ( $sect, $rest ) = split /:/, $feature;
		my ( $name, $want ) = split /=/, $rest;
		my $bool = not defined $want;
		my $test;

		$name ||= $rest;

		if ( $sect eq 'cfg' ) {
			$test = $cfg->initfs_feature_setting( $name );
		}

		else {
			warn "ignoring $feature: unknown section $sect\n";
			return;
		}

		$rv = $bool ? defined $test : $test eq $want;

	}

	else {
		$rv = $cfg->kernel_feature_enabled( $feature );
	}

	return $rv;
}


sub find_truth($$@) {
	my ( $class, $cfg, @spec ) = @_;
	my $rv = 1;

	while ( my $chk = shift @spec ) {
		my $not = 0;

		if ( $chk =~ /^\!/ ) {
			$chk =~ s/^\!//;
			$not = 1;
		}

		my $rc = is_enabled $cfg, $chk;

		if ( $not ) {
			$rc = ! $rc;
		}

		$rv &&= $rc;

		return 0 unless $rv;
	}

	return $rv;
}


1;
