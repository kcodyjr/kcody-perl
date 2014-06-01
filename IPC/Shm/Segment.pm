package IPC::Shm::Segment;
use warnings;
use strict;
use Carp;

###############################################################################
# library dependencies

use base 'IPC::Shm::Simple';

use Digest::SHA1 qw( sha1_hex );


###############################################################################
# package variables

my $IPCKEY = 0xdeadbeef;

our %Attrib = (
	varname => undef,
	varanon => undef
);


###############################################################################
###############################################################################

###############################################################################
# get the segment for a variable (by symbol), creating if needed

sub named($$) {
	my ( $class, $sym ) = @_;
	my ( $rv );

	unless ( $sym ) {
		carp __PACKAGE__ . ' cannot cope with a null symbol name';
		return undef;
	}

	if ( $sym eq '%IPC::Shm::NAMEVARS' ) {
		unless ( $rv = $class->bind( $IPCKEY ) ) {
			carp "shmbind failed: $!";
			return undef;
		}
	}

	elsif ( my $shmid = $IPC::Shm::NAMEVARS{$sym} ) {
		unless ( $rv = $class->shmat( $shmid ) ) {
			carp "shmattach failed: $!";
			return undef;
		}
	}

	else {
		unless ( $rv = $class->create ) {
			carp "shmcreate failed: $!";
			return undef;
		}
		$rv->unlock;
		$IPC::Shm::NAMEVARS{$sym} = $rv->shmid;
	}

	$rv->varname( $sym );

	return $rv;
}


###############################################################################
# attach to an anonymous segment by cookie, or create a new one

sub anonymous {
	my ( $class, $aname ) = @_;
	my ( $rv, $shmid );

	if ( defined $aname ) {

		unless ( $shmid = $IPC::Shm::ANONVARS{$aname} ) {
			carp "no such anonymous segment $aname";
			return undef;
		}

		unless ( $rv = $class->shmat( $shmid ) ) {
			carp "failed to attach to shmid $shmid: $!";
			return undef;
		}

	}

	else {
		unless ( $rv = $class->create ) {
			carp "shmcreate failed: $!";
			return undef;
		}

		$rv->unlock;
		$aname = sha1_hex( rand( 10000 ) . ' ' . $$ );
		$IPC::Shm::ANONVARS{$aname} = $rv->shmid;

	}

	$rv->varanon( $aname );

	return $rv;
}


###############################################################################
###############################################################################

###############################################################################
# produce a human-readable identifier for the variable

sub varid {
	my ( $this ) = @_;

	if ( my $vname = $this->varname ) {
		return 'NAME=' . $vname;
	}

	if ( my $vanon = $this->varanon ) {
		return 'ANON=' . $vanon;
	}

	return "UNKNOWN!";
}

###############################################################################
# determine the variable type based on its name or cookie

sub vartype {
	my ( $this ) = @_;

	if ( my $vanon = $this->varanon ) {
		return $IPC::Shm::ANONTYPE{$vanon} || 'INVALID';
	}

	my $vname = $this->varname;

	return 'HASH' if $vname =~ /^%/;
	return 'ARRAY' if $vname =~ /^@/;
	return 'SCALAR' if $vname =~ /^\$/;

	return 'INVALID';
}


###############################################################################
# generate a stand-in hashref containing one identifier or another

sub standin {
	my ( $this ) = @_;

	if    ( my $vname = $this->varname ) {
		return { varname => $vname };
	}

	elsif ( my $vanon = $this->varanon ) {
		return { varanon => $vanon };
	}

	else {
		carp __PACKAGE__ . ' object has no identifier';
		return undef;
	}

}


###############################################################################
# determine the standin variable type based on its name or cookie

sub standin_type {
	my ( $class, $standin ) = @_;

	if ( my $vanon = $standin->{varanon} ) {
		return $IPC::Shm::ANONTYPE{$vanon} || 'INVALID';
	}

	my $vname = $standin->{varname};

	return 'HASH' if $vname =~ /^%/;
	return 'ARRAY' if $vname =~ /^@/;
	return 'SCALAR' if $vname =~ /^\$/;

	return 'INVALID';
}


###############################################################################
# get back the shared memory id given a standin from above

sub standin_shmid {
	my ( $class, $standin ) = @_;

	if ( my $vname = $standin->{varname} ) {
		return $IPC::Shm::NAMEVARS{$vname};
	}

	if ( my $vanon = $standin->{varanon} ) {
		return $IPC::Shm::ANONVARS{$vanon};
	}

	return 0;
}


###############################################################################
# get back the object given a standin from above

sub restand {
	my ( $callclass, $standin ) = @_;

	my $shmid = $callclass->standin_shmid( $standin );

	unless ( $shmid ) {
		carp "could not get shmid for standin";
		return undef;
	}

	my $class = 'IPC::Shm::Tied::' . $callclass->standin_type( $standin );

	my $rv = $class->shmat( $shmid );

	unless ( $rv ) {
		carp "restand_obj shmat failed: $!\n";
		return undef;
	}

	$rv->varname( $standin->{varname} ) if $standin->{varname};
	$rv->varanon( $standin->{varanon} ) if $standin->{varanon};

	return $rv;
}


###############################################################################
# indicate a standin is being thrown away

sub discard {
	my ( $class, $standin ) = @_;

	my $this = $class->restand( $standin )
		or return undef;

	$this->decref;

	unless ( $this->nrefs ) {
		$this->CLEAR;
		$this->remove;
		if ( my $vanon = $this->varanon ) {
			delete $IPC::Shm::ANONVARS{$vanon};
			delete $IPC::Shm::ANONTYPE{$vanon};
		}
	}

}


###############################################################################
###############################################################################
1;
