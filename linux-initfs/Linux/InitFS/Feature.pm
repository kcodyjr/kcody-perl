package Linux::InitFS::Feature;
use warnings;
use strict;

use Linux::InitFS::Feature::Core;
use Linux::InitFS::Feature::LUKS;
use Linux::InitFS::Feature::LVM;
use Linux::InitFS::Feature::MD;
use Linux::InitFS::Feature::Rescue;


sub is_enabled($) {
	my ( $this, $feature ) = @_;

	$feature ||= $this;

	return Linux::InitFS::Kernel::feature_enabled( $feature );
}


sub enable_feature($) {
	my ( $name ) = @_;

	my $class = 'Linux::InitFS::Feature::' . $name;

	$class->ENABLE();

}


sub enable_features() {

	enable_feature 'Core';
	enable_feature 'Rescue';

	enable_feature 'MD'   if is_enabled 'BLK_DEV_MD';
	enable_feature 'LVM'  if is_enabled 'BLK_DEV_DM';
	enable_feature 'LUKS' if is_enabled 'DM_CRYPT';

	return 1;
}


sub ENABLE {
	my ( $class ) = @_;

	$class =~ s/.*:://g;

	warn "Unimplemented feature $class\n";

}


1;
