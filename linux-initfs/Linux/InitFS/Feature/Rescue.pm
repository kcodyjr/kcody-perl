package Linux::InitFS::Feature::Rescue;
use warnings;
use strict;

use base 'Linux::InitFS::Feature';


sub ENABLE {

	Linux::InitFS::Entry->new_host_prog( '/bin/bash' );
	Linux::InitFS::Entry->new_host_file( '/etc/inputrc' );

}



1;
