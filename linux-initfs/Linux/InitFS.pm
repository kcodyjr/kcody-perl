package Linux::InitFS;
use warnings;
use strict;

our $VERSION = 0.1;

use Linux::InitFS::Entry;


sub generate {
	my ( $this ) = @_;

	return Linux::InitFS::Entry->execute();
}


1;
