package IPC::Shm::Segment;
use warnings;
use strict;
use Carp;

###############################################################################
# library dependencies

use base 'IPC::Shm::Simple';

use Digest::SHA1	qw( sha1_hex );

our %OURNAME;
our %OURANON;
our %LEXICAL;

my $IPCKEY = 0xdeadbeef;



sub varname {
	my $this = shift;
	if ( my $newval = shift ) {
		return $this->{varname} = $newval;
	}
	return $this->{varname};
}

sub varanon {
	my $this = shift;
	if ( my $newval = shift ) {
		return $this->{varanon} = $newval;
	}
	return $this->{varanon};
}


###############################################################################
# stand-in hashref containing one identifier or another

sub standin {
	my ( $this ) = @_;

	if    ( my $vname = $this->varname ) {
		return { varname => $vname };
	}

	elsif ( my $vanon = $this->varanon ) {
		return { varanon => $vanon };
	}

	else {
		carp __PACKAGE__.' object has no identifier';
		return undef;
	}

}


###############################################################################
# get back the object given a standin from above

sub restand {
	my ( $this, $standin ) = @_;
	my ( $rv );

	if    ( my $vname = $standin->{varname} ) {
		$rv = $this->named( $vname );
		$rv->varname( $vname );
	}

	elsif ( my $vanon = $standin->{varanon} ) {
		$rv = $this->anonymous( $vanon );
		$rv->varanon( $vanon );
		$rv->retie unless $rv->isa( 'IPC::Shm::Tied' );
	}

	else {
		carp __PACKAGE__.' standin has no identifier';
		return undef;
	}

	return $rv;
}


###############################################################################
# retie a shared segment

sub retie {
	my ( $this ) = @_;

	my $type = $IPC::Shm::ANONTYPE{$this->varanon};

	if ( $type eq 'HASH' ) {
		tie my %tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( \%tmp );
	}

	elsif ( $type eq 'ARRAY' ) {
		tie my @tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( \@tmp );
	}

	elsif ( $type eq 'SCALAR' ) {
		tie my $tmp, 'IPC::Shm::Tied', $this;
		$this->tiedref( \$tmp );
	}

	else {
		confess "unknown reference type";
	}

}


###############################################################################
# common methods

sub rebless {
	my ( $class, $store, @args ) = @_;

	my $this = bless $store, $class;

	$this->incref;

	return $this;
}

sub DESTROY {
	my ( $this ) = @_;
print "segment destroying\n";
	$this->decref;
	$this->SUPER::DESTROY;

}


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
		$IPC::Shm::NAMEVARS{$sym} = $rv->shmid;
	}

	$rv->varname( $sym );

	return $rv;
}


###############################################################################
# get the anonymous segment for a lexical (by reference), creating if needed

sub lexical($$) {
	my ( $class, $ref ) = @_;
	my ( $rv );

	if ( my $aname = $LEXICAL{$ref} ) {
		print "reattaching lexical\n";
		return $class->anonymous( $aname );
	}

	$rv = $class->anonymous;

	$LEXICAL{$ref} = $rv->varanon;

	return $rv;
}

###############################################################################
# create an identifier for an anonymous segment

sub _new_anonymous_name {
	return sha1_hex( rand( 10000 ) . ' ' . $$ );
}


###############################################################################
# attach to an anonymous segment by cookie

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
		$aname = _new_anonymous_name();
		$IPC::Shm::ANONVARS{$aname} = $rv->shmid;

	}

	$rv->varanon( $aname );
	$OURANON{$aname} = $rv->standin;

	return $rv;
}


###############################################################################
###############################################################################

###############################################################################
# garbage collection

sub END {

	foreach my $vanon ( keys %OURANON ) {
		my $stand = $OURANON{$vanon};

		my $share = __PACKAGE__->restand( $stand );
		next unless $share;

		$share->decref;
		next if $share->nrefs;

		delete $IPC::Shm::ANONVARS{$vanon};
		delete $IPC::Shm::ANONTYPE{$vanon};
		$share->remove;

	}

}


###############################################################################
###############################################################################
1;
