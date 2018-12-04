package Linux::InitFS::Config;
use warnings;
use strict;

use Linux::InitFS::Kernel;

use File::ShareDir;


my $CFGBASE = File::ShareDir::dist_dir( 'Linux-InitFS' );
my $DEFAULT = $CFGBASE . '/config/default';
my $CFGROOT = '/etc/default/Linux-InitFS';
my $CFGUSER = $ENV{HOME} . '/.initfs_config';


sub new($) {
	my ( $class ) = @_;

	die "no class given" unless $class;

	return bless {}, $class;
}


sub _import_config_file {
	my ( $rv, $file ) = @_;

	return 0 unless -r $file;

	open my $fh, '<', $file
		or die "open($file): $!";

	while ( <$fh> ) {
		chomp;
		s/#.*//;
		s/^\s+//;
		s/\s+$//;
		next unless $_;

		my ( $key, $val ) = split /\s*=\s*/;

		if ( defined $val ) {
			$key =~ s/^CONFIG_//;
		}

		else {
			$key = $_;
			$val = 1;
		}

		$rv->{$key} = $val;

	}

	return scalar keys %$rv;
}


sub import_initfs_config {
	my ( $self, $path ) = @_;

	my $rv = $self->{initfs} ||= {};
	my $rc = 0;

	if ( $path ) {
		my $file = $path . '/.config_initfs';
		$rc = _import_config_file $rv, $file;
	}

	else {
		$rc  = _import_config_file $rv, $DEFAULT;
		$rc += _import_config_file $rv, $CFGROOT;
		$rc += _import_config_file $rv, $CFGUSER;
	}

	return $rc;
}


sub import_kernel_config {
	my ( $self, $path ) = @_;

	my $rv = $self->{kernel} ||= {};

	return _import_config_file $rv, $path . '/.config';
}


sub initfs_feature_setting {
	my ( $self, $cfgkey ) = @_;

	return unless $cfgkey;
	return unless $self->{initfs};

	return $self->{initfs}->{$cfgkey};
}


sub kernel_feature_enabled {
	my ( $self, $cfgkey ) = @_;

	return unless $cfgkey;
	return unless $self->{kernel};
	return unless $self->{kernel}->{$cfgkey};

	return $self->{kernel}->{$cfgkey} eq 'y';
}


1;
