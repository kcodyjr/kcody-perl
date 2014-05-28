package IPC::Shm::Simple;

use strict;

#
# Copyright (C) 2005,2014 by Kevin Cody-Little <kcody@cpan.org>
#
# Although this package as a whole is derived from
# IPC::ShareLite, this particular file is a new work.
# 
# This code may be modified or redistributed under the terms
# of either the Artistic or GNU General Public licenses, at
# the modifier or redistributor's discretion.
#

=head1 NAME

IPC::Shm::Simple - Simple Data in SysV Shared Memory Segments

=head1 SYNOPSIS

Provides the ability to create a shared segment with or without first
knowing what ipckey it will use. Optionally caches shared memory reads
in process memory, and defeatably verifies writes by reading the value back
and comparing it stringwise.

=head1 TODO

=over

=item 1. Document _init interface and _fresh interface

=item 2. Trap thread creation and wipe ObjCache/ObjOwner

=item 3. Complete API documentation

=item 4. Add portability documentation

=item 5. Change valid to is_valid

=back

=cut


use Carp;
use Fcntl qw( :flock );
use IPC::SysV qw( IPC_PRIVATE );

use Class::Attrib;
use DynaLoader;
use UNIVERSAL;

use vars qw( $VERSION @ISA %Attrib );

$VERSION = '1.04';
@ISA     = qw( Class::Attrib DynaLoader );
%Attrib  = (
	Mode		=> 0660,
	Size		=> 4096,
	dwell		=> 0,
	verify		=> 1
);

my $PACKAGE = __PACKAGE__ . '';


###
### Constructors
###

=head1 CONSTRUCTORS

=head2 $this->bind( ipckey, [size], [mode] );

Attach to the shared memory segment identified by ipckey, whether it
exists already or not.

If a segment must be created, size and permissions may be specified as
for the C<< $this->create() >> call. Otherwise, the class defaults will apply.

Returns blessed reference on success, undef on failure.

Throws an exception on invalid parameters.

=cut

sub bind($$) {
	my ( $this, $ipckey, $size, $mode ) = @_;
	my ( $self );

	unless ( $self = $this->attach( $ipckey ) ) {
		$self = $this->create( $ipckey, $size, $mode );
		$self->unlock;
	}

	return $self;
}

{ # BEGIN ObjCache and ObjIndex lexical scope
my %ObjIndex = ();		# cache key=ipckey value=shmid
my %ObjCache = ();		# cache key=shmid  value=instance

=head2 $this->attach( ipckey );

Attach to the shared memory segment identified by ipckey if it exists.

Returns blessed reference on success, undef on failure.

Throws an exception on invalid parameters.

=cut

sub attach($$) {
	my ( $this, $ipckey ) = @_;
	my ( $share, $self );

	confess( __PACKAGE__ . "->attach: Called without ipckey." )
		unless defined $ipckey;

	confess( __PACKAGE__ . "->attach: Called with empty ipckey." )
		unless $ipckey;

	confess( __PACKAGE__ . "->attach: Called with string ipckey." )
		unless $ipckey > 0;

	confess( __PACKAGE__ . "->attach: Called with IPC_PRIVATE." )
		if $ipckey == IPC_PRIVATE;

	# NOTE: using $share as private shmid here
	if ( $share = $ObjIndex{$ipckey} ) {
		if ( $self = $ObjCache{$share} ) {
			return $self if $self->is_valid;
			delete $ObjCache{$share};
		}
		delete $ObjIndex{$ipckey};
	}

	# NOTE: using $share as sharelite handle here
	$share = sharelite_attach( $ipckey )
		or return undef;

	bless $self = {}, ref( $this ) || $this;

	$self->{share} = $share;

	# inform subclasses that an uncached attachment has occurred
	$self->_attach()
		or return undef;

	# save the attached object in the cache
	$ObjIndex{$ipckey} = sharelite_shmid( $share );
	$ObjCache{$ObjIndex{$ipckey}} = $self;

	return $self;
}

sub _attach($) {
	my ( $self ) = @_;

	return 1;
}

=head2 $this->create( [ipckey], [segsize], [permissions] )

Create a new shared memory segment, with the given ipckey, unless it exists.
Can be given C<IPC_PRIVATE> as an ipckey to create an unkeyed segment, which
is assumed if no argument is provided.

The optional parameters segsize and permissions default to C<< $this->Size() >>
and C<< $this->Mode() >>, respectively.

Returns blessed reference on success, undef on failure.

=cut

sub create($;$) {
	my ( $this, $ipckey, $size, $mode ) = @_;
	my ( $share, $class, $self );

	$ipckey ||= IPC_PRIVATE;
	$size   ||= $this->Size();
	$mode   ||= $this->Mode();

	$class = ref( $this ) || $this;

	$share = sharelite_create( $ipckey, $size, $mode )
		or return undef;

	bless $self = {}, $class;

	$self->{share} = $share;

	my $shmid = sharelite_shmid( $share );

	$ObjIndex{$ipckey} = $shmid
		unless $ipckey == IPC_PRIVATE;

	$ObjCache{$shmid} = $self;

	return $self;
}

=head2 $this->shmat( shmid );

Attach to an existing shared memory segment by its shmid.

=cut

sub shmat($$) {
	my ( $this, $shmid ) = @_;
	my ( $share, $self );

	confess( __PACKAGE__ . "->shmat: Called without shmid." )
		unless defined $shmid;

	confess( __PACKAGE__ . "->shmat: Called with empty shmid." )
		unless $shmid;

	confess( __PACKAGE__ . "->shmat: Called with string shmid." )
		unless $shmid != 0;

	confess( __PACKAGE__ . "->shmat: Called with invalid shmid." )
		if $shmid == -1;

	# NOTE: using share as private shmid here
	if ( $self = $ObjCache{$shmid} ) {
		return $self if $self->is_valid;
		delete $ObjCache{$shmid};
	}

	# NOTE: using share as sharelite handle here
	$share = sharelite_shmat( $shmid )
		or return undef;

	bless $self = {}, ref( $this ) || $this;

	$self->{share} = $share;

	# inform subclasses that an uncached attachment has occurred
	$self->_attach()
		or return undef;

	# save the attached object in the cache
	$ObjCache{$shmid} = $self;

	return $self;
}

=head1 CLEANUP METHOD

=head2 $self->remove();

Uncaches the referenced instance, and causes the underlying shared
memory segments to be removed from the operating system when DESTROYed.

Returns 1 on success, undef on failure.

=cut

sub remove($) {
	my ( $self ) = @_;
	my ( $share, $shmid, $ipckey );

	$share  = $self->{share}
		or return undef;

	$shmid  = sharelite_shmid( $share );
	$ipckey = sharelite_key( $share );

	delete $ObjCache{$shmid};
	delete $ObjIndex{$ipckey};

	return ( sharelite_remove( $share ) == -1 ) ? undef : 1;
}

} # END scope


# when the object is destroyed, the sharelite object must be too
# otherwise segment removal (and even removal marking) would never occur
sub DESTROY($) {

	sharelite_shmdt( shift->{share} );

	return;
}


=head1 ACCESSOR METHODS

=head2 $self->key();

Returns the ipckey assigned by the program at instantiation.

=head2 $self->shmid();

Returns the shmid assigned by the operating system at instantiation.

=head2 $self->flags();

Returns the permissions flags assigned at instantiation.

=head2 $self->length();

Returns the number of bytes currently stored in the share.

=head2 $self->serial();

Returns the serial number of the current shared memory value.

=head2 $self->top_seg_size();

Returns the total size of the top share segment, in bytes.

=head2 $self->chunk_seg_size();

Returns the size of data chunk segments, in bytes.

=head2 $self->chunk_seg_size( chunk_segment_size );

Changes the size of chunk data segments. The share must have only one
allocated segment (the top segment) for this call to succeed.

=head2 $self->nrefs();

Returns the current shared reference count.

=head2 $self->incref();

Increments the shared reference counter.

=head2 $self->decref();

Decrements the shared reference counter.

=cut

sub key($) {
	return sharelite_key( shift->{share} );
}

sub shmid($) {
	return sharelite_shmid( shift->{share} );
}

sub flags($) {
	return sharelite_flags( shift->{share} );
}

sub length($) {
	return sharelite_length( shift->{share} );
}

sub serial($) {
	return sharelite_serial( shift->{share} );
}

sub is_valid($) {
	return sharelite_is_valid( shift->{share} );
}

sub nsegments($) {
	return sharelite_nsegments( shift->{share} );
}

sub top_seg_size($) {
	return sharelite_top_seg_size( shift->{share} );
}

sub chunk_seg_size($;$) {
	return sharelite_chunk_seg_size( shift->{share}, @_ );
}

sub nrefs($;$) {
	return sharelite_nrefs( shift->{share}, @_ );
}

sub incref($;$) {
	return sharelite_incref( shift->{share}, @_ );
}

sub decref($;$) {
	return sharelite_decref( shift->{share}, @_ );
}


=head1 DATA METHODS

=head2 $self->scache();

Returns a scalar reference to the segment cache. Does not guarantee
freshness, and the reference can become invalid after the next I/O
operation.

=head2 $self->fetch();

Fetch a previously stored value. If a subclass defines a C<_fresh> method,
it will be called only when the shared memory value is changed by another
process. If nothing has been stored yet, C<undef> is returned.

=cut

sub scache($) {
	my $self = shift;

	return undef unless defined $self->{scache};

	return \($self->{scache});
}

sub fetch($) {
	my $self = shift;

	carp(  __PACKAGE__ . "->fetch: Called without at least shared lock!" )
		if $self->_locked( LOCK_UN );

	# determine current shared memory value serial number
	my $serial = sharelite_serial( $self->{share} );

	# short circuit remaining tests if cache is found invalid
	my $dofetch = 0;

	# definitely fetch if we don't have a matching serial number
	$dofetch = 1
		unless $self->{serial} && ( $self->{serial} == $serial );

	# same serial; believe the cached value if it isn't too old
	# a zero ttl means trust the cached value until the serial changes
	unless ( $dofetch ) {
		if ( my $ttl = $self->dwell() ) {
			$dofetch = 1 if $self->{sstamp} + $ttl < time();
		}
	}

	if ( $dofetch ) {
		my $data = sharelite_fetch( $self->{share} );

		croak( __PACKAGE__ . "->fetch: failed: $!" )
			unless defined $data;

		# only bother with strcmp if a subclass cares about changes
		if ( my $cref = UNIVERSAL::can( $self, '_fresh' ) ) {
			my $changed = defined $self->{scache}
					? $data eq $self->{scache}
					: 1;
			$self->{scache} = $data;
			&$cref( $self ) if $changed;
		} else {
			$self->{scache} = $data;
		}

		$self->{sstamp} = time();
		$self->{serial} = $serial;

	}

	return $self->{scache};
}

=head2 $self->store( value );

Stores a string or numeric value in the shared memory segment.

=cut

sub store($$) {
	my $self = shift;

	carp(  __PACKAGE__ . "->store: Called without exclusive lock!" )
		unless $self->_locked( LOCK_EX );

	my $rc = sharelite_store( $self->{share}, $_[0], CORE::length( $_[0] ) );

	croak( __PACKAGE__ . "->store: failed: $!" )
		if $rc == -1;

	if ( $self->verify() ) {
		my $data = sharelite_fetch( $self->{share} );

		croak( __PACKAGE__ . "->store: fetch failed: $!" )
			unless defined $data;
		
		croak( __PACKAGE__ . "->store: Write verify failed!" )
			unless $_[0] eq $data;

	}

	# simulate a fetch because storing also serves to confirm the value
	$self->{scache} = $_[0];
	$self->{sstamp} = time();
	$self->{serial} = sharelite_serial( $self->{share} );

	# return true so test harnesses pass
	return 1;
}


###
### Object Lock Methods - Class::Lockable friendly
###

sub lock($$) {
	return shift->_lock( @_ );
}

sub _lock($$) {
	my ( $self, $flag ) = @_;
	my $rc;

	# short circuit if already locked as requested
	return 0 if sharelite_locked( $self->{share}, $flag );

	my $rc = sharelite_lock( $self->{share}, $flag );

	if ( $rc == -1 ) {
		carp( __PACKAGE__ . "->_lock: $!" );
		return undef;
	}

	return $rc == 0;
}

sub locked($$) {
	return shift->_locked( @_ );
}

sub _locked($$) {
	my ( $self, $flag ) = @_;

	my $rc = sharelite_locked( $self->{share}, $flag );

	if ( $rc == -1 ) {
		carp( __PACKAGE__ . "->_locked: $!" );
		return undef;
	}

	return $rc != 0;
}


###
### Higher Level Lock Methods
###

sub unlock($) {
	return shift->lock( LOCK_UN );
}

sub readlock($) {
	return shift->lock( LOCK_SH );
}

sub writelock($) {
	return shift->lock( LOCK_EX );
}


bootstrap IPC::Shm::Simple $VERSION;

1;


=head1 INSTANCE ATTRIBUTES - I/O BEHAVIOR

=head2 $this->dwell( [seconds] );

Specifies the time-to-live of cached shared memory reads, in seconds.
This only affects the case where the serial number has -not- changed.

Default: 0.

=head2 $this->verify( [boolean] );

Specifies whether to read-back and compare shared memory writes.

Expensive.

Default: 1.

=head1 PACKAGE ATTRIBUTES - SEGMENT PARAMETERS

These methods carry the default values used during instantiation.

=head2 $this->Mode( [value] );

Specifies or fetches the permissions for new segments. Default: 0660.

=head2 $this->Size( [value] );

Specifies or fetches the initial size of new shared memory segments.
Default: 4096

=head1 CAVEATS

To do.

=cut

