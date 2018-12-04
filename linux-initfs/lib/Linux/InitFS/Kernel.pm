package Linux::InitFS::Kernel;
use warnings;
use strict;

use base qw( Exporter );
our @EXPORT = qw( &detect_kconfig_here );

use Cwd;


my %kconfig_path;


sub __detect_kconfig_here {
	my ( $path ) = @_;

	my $full = $path . '/Kconfig';

	if ( -f $full and -r $full ) {
		return $path;
	}

	my @part = split /\//, $path;
	pop @part;

	return unless scalar @part;

	my $next = join( '/', @part );

	return __detect_kconfig_here( $next );
}


sub _detect_kconfig_here {
	my ( $path ) = @_;

	return undef unless $path;

	if ( $kconfig_path{$path} ) {
		return $kconfig_path{$path};
	}

	my $rv = __detect_kconfig_here( $path )
		or return undef;

	return $kconfig_path{$path} = $rv;
}


sub detect_kconfig_here(;$) {
	my ( $path ) = @_;

	return _detect_kconfig_here( $path || getcwd() );
}


1;
