package Linux::InitFS::Feature::LVM;
use warnings;
use strict;

use base 'Linux::InitFS::Feature';


sub ENABLE {

	Linux::InitFS::Entry->new_host_file( '/sbin/lvm' );

}


1;
