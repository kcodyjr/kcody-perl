package IPC::Shm::Simple;

#
# Copyright (C) 2005 by K Cody <kcody@jilcraft.com>
# Do not distribute under any circumstances whatsoever.
# All rights explicitly reserved by K Cody.
#

=head1 NAME

IPC::Shm::Simple - Simple Data in SysV Shared Memory Segments

=head1 SYNOPSIS

Provides the ability to create a shared segment with or without first
knowing what ipckey it will use. Optionally caches shared memory reads
in process memory, and defeatably verifies writes by reading the value back
and comparing it stringwise.

This class is implemented internally using IPC::ShareLite.

=head1 TODO

=over

=item 1. Document _init interface and _fresh interface

=item 2. Check whether ShareLite checks validity on reattach

=item 3. Add %ObjOwner to track instance cache entries across forks

=item 4. Trap thread creation and wipe ObjCache/ObjOwner

=item 5. Can ShareLite work with shmid's instead of ipckey's?

=item 6. Trap disappeared segments (in lock?) so ShareLite won't recreate

=back

=cut

use strict;
use warnings;


###
### Module Dependencies
###

use Carp;
use Class::Attrib;
use Class::Lockable;
use IPC::ShareLite qw( :lock );

our @ISA = qw( Class::Attrib Class::Lockable );

our %Attrib = (
	Mode		=> 0660,
	Ntry		=> 100,
	Size		=> 65535,
	dwell		=> 0,
	verify		=> 1
);


###
### Constructors
###

=head1 CONSTRUCTORS

=head2 $this->bind( ipckey );

Attach to the shared memory segment identified by ipckey, whether it
exists already or not.

=cut

sub bind($$) {
	my ( $this, $ipckey ) = @_;
	my ( $self );

	unless ( $self = $this->attach( $ipckey ) ) {
		$self = $this->create( $ipckey );
		$self->unlock();
	}

	return $self;
}

=head2 $this->attach( ipckey );

Attach to the shared memory segment identified by ipckey if it exists.

=cut

sub attach($$) {
	my ( $this, $ipckey ) = @_;

	croak( __PACKAGE__ . "->attach: Called without ipckey." )
		unless defined $ipckey;

	croak( __PACKAGE__ . "->attach: Called with empty ipckey." )
		unless $ipckey;

	croak( __PACKAGE__ . "->attach: Called with string ipckey." )
		unless $ipckey > 0;

	return $this->_new( $ipckey, 0 );
}

=head2 $this->create();

Create a new shared memory segment with any unused ipckey.

=head2 $this->create( ipckey )

Create a new shared memory segment, with the given ipckey, unless it exists.

=cut

sub create($;$) {
	my ( $this, $ipckey ) = @_;
	my $self = $this->_new( $ipckey, 1 );

	return undef unless $self;

	$self->exlock();

	return $self;
}


###
### Instance Input-Output Methods
###

=head1 KEY METHOD

=head2 $self->key();

Returns the ipckey assigned at instantiation.

=cut

sub key($) {
	my ( $self ) = @_;

	confess( __PACKAGE__ . "->key: Called on class reference!\n" )
		unless ref $self;

	return $self->{_key};
}

=head1 DATA METHODS

=head2 $self->fetch();

Fetch a previously stored value. If a subclass defines a C<_fresh> method,
it will be called only when the shared memory value is changed by another
process. If nothing has been stored yet, C<undef> is returned.

=cut

sub fetch($) {
	my $self = shift;
	my ( $secs, $stale, $data );

	confess( __PACKAGE__ . "->fetch: Called on class reference!" )
		unless ref( $self );

	# short circuit dwell if there is no value cached in process memory
	$secs = defined $self->{_sstamp}
		? $self->dwell()
		: 0;

	# decide whether the value cached in process memory is still valid
	$stale = $secs > 0
		? $self->{_sstamp} + $secs > time()
		: 1;

	if ( $stale ) {

		croak( __PACKAGE__ . "->fetch: failed: $!" )
			unless defined eval { $data = $self->{_shm}->fetch() };

		# only bother with strcmp if a subclass cares about changes
		if ( $self->can( '_fresh' ) ) {
			$self->_fresh( $self->{_scache} = $data )
				unless $data eq $self->{_scache};
		} else {
			$self->{_scache} = $data;
		}

		$self->{_sstamp} = time();

	}

	return $self->{_scache};
}

=head2 $self->store( value );

Stores a string or numeric value in the shared memory segment.

=cut

sub store($$) {
	my $self = shift;

	confess( __PACKAGE__ . "->store: Called on class reference!" )
		unless ref( $self );

	carp(  __PACKAGE__ . "->store: Called without exclusive lock!" )
		unless $self->locked();

	croak( __PACKAGE__ . "->store: failed: $!" )
		unless defined eval { $self->{_shm}->store( $_[0] ) };

	if ( $self->verify() ) {
		my $data;

		croak( __PACKAGE__ . "->store: fetch failed: $!" )
			unless defined eval { $data = $self->{_shm}->fetch() };
		
		croak( __PACKAGE__ . "->store: Write verify failed!" )
			unless $_[0] eq $data;

	}

	# simulate a fetch because storing also serves to confirm the value
	$self->{_scache} = $_[0];
	$self->{_sstamp} = time();

	return;
}


###
### Underlying Object Lock Method
###

sub _lock($$) {
	my ( $self, $flag ) = @_;
	my $rc;

	if ( $rc = $self->{_shm}->lock( $flag ) ) {

		$self->{_lock} = $flag;
	} elsif ( not defined $rc ) {

		# IPC::ShareLite->lock returns 0 on busy, undef on failure
		carp( __PACKAGE__ . "->lock: failed: $!" );
	}

	return defined $rc ? $rc != 0 : 0;
}


=head1 INSTANCE ATTRIBUTES - I/O BEHAVIOR

=head2 $this->dwell();

Specifies the time-to-live of cached shared memory reads, in seconds.
Default: 0.

=head2 $this->verify();

Specifies whether to read-back and compare shared memory writes.  Default: 1.

=head1 PACKAGE ATTRIBUTES - SEGMENT PARAMETERS

These methods carry values used during shm segment creation, thus although
they can be set on an instance, doing so is completely superfluous.

=head2 $this->Mode( value );

Specifies or fetches the permissions for new segments. Default: 0660.

=head2 $this->Ntry( value );

Specifies or fetches the number of ipckeys C<create> will try before giving up.
Default: 100.

=head2 $this->Size( value );

Specifies or fetches the initial size of new shared memory segments.
Default: 65536 (FIXME)

=cut


###
### Class Support Methods
###

{ # BEGIN $NextIpcKey scope
my $NextIpcKey = 0x4C524550;	# 'PERL'

# FIXME: switch to random selection
sub _Next($) {
	shift;	# disregard class/instance reference
	return $NextIpcKey++;
}

} # END $NextIpcKey scope

# set initial values for instance attributes
sub _init($) {
	my ( $self ) = @_;

	$self->{_lock}   = LOCK_UN;
	$self->{_locks}  = [];
	$self->{_rlocks} = 0;
	$self->{_wlocks} = 0;
	$self->{_sstamp} = 0;
	$self->{_scache} = '';

	return;
}

# open the IPC::ShareLite handle with the given behaviors
sub _shmattach($$$$) {
	my ( $this, $ipckey, $create, $destroy ) = @_;
	my ( %options );

	$create  |= 0;		# set to zero if undefined, avoid warning
	$destroy |= 0;

	croak( __PACKAGE__ . "::_shmattach: Called without valid ipckey." )
		unless $ipckey > 0;

	$options{-key}		= $ipckey;
	$options{-create}	= $create  != 0;
	$options{-exclusive}	= $create  != 0;
	$options{-destroy}	= $destroy != 0;
	$options{-mode}		= $this->Mode();
	$options{-size}		= $this->Size();

	return IPC::ShareLite->new( %options );
}


{ # BEGIN ObjCache lexical scope
my %ObjCache = ();

# keep attempting to create segments until an available one is found
# returns a list containing first the ShareLite handle, then its ipckey
sub _shmalloc($) {
	my ( $this ) = @_;
	my ( $shm, $key );

	for ( my $i = 0; $i < $this->Ntry() ; $i++ ) {
		next if $ObjCache{ $key = $this->_Next() };
		$shm = $this->_shmattach( $key, 1, 0 );
		last if $shm;
	}

	return ( $shm, $key );
}

# common constructor has to create the shm handle as required by the
# calling constructors, -then- use its key to create the base object
sub _new($$$) {
	my ( $this, $ipckey, $create ) = @_;
	my ( $self, $shm, $key );

	if ( $ipckey ) {

		if ( $self = $ObjCache{$ipckey} ) {
			return $create ? undef : $self;
		}

		$shm = $this->_shmattach( $key = $ipckey, $create, 0 );

	} else {

		( $shm, $key ) = $this->_shmalloc();

	}

	return undef unless $shm;
	return undef unless $self = $this->SUPER::_new();

	$ObjCache{$key} = $self;
	$self->_init();

	$self->{_key} = $key;
	$self->{_shm} = $shm;

	return $self;
}

=head1 CLEANUP METHOD

=head2 $self->free();

Uncaches the referenced instance, and removes the underlying shared memory
segment from the operating system.

=cut

sub free($) {
	my ( $self ) = @_;

	confess( __PACKAGE__ . "->remove: Called on class reference!" )
		unless ref( $self );

	# remove process-local instance cache entry
	delete $ObjCache{ $self->key() };

	# remove the IPC::ShareLite reference
	delete $self->{_shm};

	# create a new IPC::ShareLite reference with the destroy flag
	# the segment will be removed when the new reference is forgotten
	$self->_shmattach( $self->key(), 0, 1 );

	return;
}

} # END ObjCache lexical scope


1;

=head1 CAVEATS

To do.

=head1 SEE ALSO

=over

=item C<IPC::Shm::Storable> for a subclass that can store references.

=item C<IPC::Shm::Item> for a subclass that can store blessed references.

=item "man L<ipcs>" for more details on shared memory segments.

=back

=cut

