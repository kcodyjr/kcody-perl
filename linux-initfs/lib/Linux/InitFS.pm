package Linux::InitFS;
use warnings;
use strict;

use 5.10.0;

our $VERSION = 0.2;


use Linux::InitFS::Entry;
use Linux::InitFS::Config;
use Linux::InitFS::Feature;


sub new {
	my ( $this ) = @_;

	my $class = ref( $this ) || $this;

	my $self = bless {}, $class;

	# create the config context as well
	$self->{config} = Linux::InitFS::Config->new
		or return;

	return $self;
}


sub cfg {
	my ( $self ) = @_;

	return $self->{config};
}


sub add_entry {
	my ( $self, $entry ) = @_;

	return unless $entry;

	$self->{entry} ||= {};

	$self->{entry}->{$entry->label} = $entry;

	return 1;
}


sub has_entry {
	my ( $self, $label ) = @_;

	return unless $label;
	return unless $self->{entry};

	return $self->{entry}->{$label};
}


sub analyze_enabled_features {
	my ( $self ) = @_;

	my $initfs = Linux::InitFS::Spec->new( 'initfs' );
		# FIXME or die?

	foreach my $spec ( @$initfs ) {
		my $subsys = shift @$spec;

		my $doit = Linux::InitFS::Feature->find_truth( $self->cfg, @$spec );

		Linux::InitFS::Feature->enable_feature( $self, $subsys )
			if $doit;

	}

	return 1;
}


sub generate_cpio_spec($) {
	my ( $self ) = @_;

	return Linux::InitFS::Entry->execute( $self->{entry} );
}


1;
