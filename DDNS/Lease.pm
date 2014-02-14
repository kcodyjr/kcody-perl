package Net::OpenVPN::DDNS::Lease;
use warnings;
use strict;
#
# Attempts to snarf client identification from an ISC dhcpd leases file.
# 
###############################################################################
#

use IO::File;

sub new {
	my ( $class, $file ) = @_;

	$class = ref( $class ) if ref( $class );

	bless my $self = { file => $file }, $class;

	$self->reread;

	return $self;
}

sub process {
	my $in = shift;
	my $rv;

	if ( $in =~ /^"/ ) {
		return eval $in;
	}

	$in =~ s/%/%%/g;

	return sprintf $in;

} 

sub reread {
	my $self = shift;

	my @in;

	my $fh = IO::File->new;
	$fh->open( "< /var/lib/dhcp/dhcpd.leases" );
	while ( <$fh> ) { push @in, $_; }
	$fh->close;

	my %LEASES;
	my $inlease = undef;

	foreach my $in ( @in ) {

		if ( $in =~ /^lease/ ) {

			if ( $inlease ) {
				warn "parse error: expected }\n";
			}

			my @parts = split /\s+/, $in;
			my $addr = $parts[1];

			$LEASES{ $inlease = $addr } = {};
			next;
		}

		if ( $in =~ /\}/ ) {
			$inlease = undef;
			next;
		}

		$in =~ s/^\s+//;
		$in =~ s/\s+$//;
		$in =~ s/;$//;

		my @parts = split /\s+/, $in;
		my $first = shift @parts;

		if ( $first eq 'uid' ) {
			$LEASES{$inlease}->{dcid} = process( shift @parts );
			next;
		}

		if ( $first eq 'hardware' ) {
			next unless shift( @parts ) eq 'ethernet';
			$LEASES{$inlease}->{hwaddr} = process( shift @parts );
			next;
		}

		if ( $first eq 'client-hostname' ) {
			$LEASES{$inlease}->{name} = process( shift @parts );
			next;
		}

		if ( $first eq 'set' ) {
			$first = shift( @parts );
			shift( @parts );
		}

		if ( $first eq 'ddns-fwd-name' ) {
			$LEASES{$inlease}->{fqdn} = process( shift @parts );
		}
	}

	my %NAMES;

	foreach my $lease ( values %LEASES ) {
		next unless $lease->{name};
		$NAMES{$lease->{name}} = $lease;
	}

	$self->{names} = \%NAMES;

}

sub client {
	my ( $self, $name ) = @_;

	return $self->{names}->{$name} || {};
}


###############################################################################
1;
