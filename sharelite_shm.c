
/*
 * sharelite_shm.c - part of IPC::Shm::Simple
 *
 * Derived from parts of IPC::ShareLite by Maurice Aubrey.
 *
 * Copyright (c) 2/2005 by K Cody <kcody@jilcraft.com>
 *
 * This code may be modified or redistributed under the terms
 * of either the Artistic or GNU General Public licenses, at
 * the modifier or redistributor's discretion.
 *
 */

#include <stdlib.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#include "sharelite.h"
#include "sharelite_shm.h"

/* --- SHARED SEGMENT NODE FUNCTIONS --- */

/* shmat to an existing segment and return a valid Node structure */
Node *_shmseg_shmat( int shmid ) {
	char *shmaddr;
	Node *node;

	if ( ( shmaddr = shmat( shmid, (char *) NULL, 0 ) ) == NULL )
		return NULL;

	if ( ( node = malloc( sizeof( Node ) ) ) == NULL ) {
		errno = ENOMEM; /* is this the right thing to do? */
		return NULL;
	}

	node->shmid   = shmid;
	node->shmhead = (Header *) shmaddr;
	node->shmdata = shmaddr + sizeof( Header );

	node->next    = NULL;
	node->shminfo = NULL;

	return node;
}

/* shmget a new segment and return a valid Node structure */
Node *_shmseg_alloc( Share *share ) {
	int flags, ssize, shmid, is_top_node;
	key_t ipckey;
	Node *node;

	flags = share->flags | IPC_CREAT | IPC_EXCL;

	if ( share->head == NULL ) {
		/* allocating the top segment */
		ssize  = share->size_top;
		ipckey = share->key;
		is_top_node = 1;
	} else {
		/* allocating a linked segment */
		ssize  = share->size_seg;
		ipckey = IPC_PRIVATE;
		is_top_node = 0;
	}

	if ( ( shmid = shmget( ipckey, ssize, flags ) ) == -1 )
		return NULL;

	if ( ( node = _shmseg_shmat( shmid ) ) == NULL )
		return NULL;

	node->shmhead->shm_magic  = SHARELITE_MAGIC;
	node->shmhead->next_shmid = -1;

	if ( is_top_node ) {
		node->shminfo  = (Descriptor *) node->shmdata;
		node->shmdata += sizeof( Descriptor );
		node->shminfo->seg_semid   = -1;
		node->shminfo->data_serial = 0;
		node->shminfo->data_length = 0;
	}

	return node;
}


/* shmdt from a segment and free its Node structure */
int _shmseg_shmdt( Node *node ) {

	if ( shmdt( node->shmhead ) == -1 )
		return -1;

	free( node );

	return 0;
}

/* shmdt from a segment, remove it, and free its Node structure */
int _shmseg_undef( Share *share, Node *node ) {
	int rc, shmid;

	shmid = node->shmid;

	if ( _shmseg_shmdt( node ) == -1 )
		return -errno;

	if ( shmctl( shmid, IPC_RMID, NULL ) == -1 )
		return -errno;

	return 0;
}


/* --- SHARED SEGMENT LIST FUNCTIONS --- */

/* attach the next segment, creating one if necessary */
int _shmseg_append( Share *share ) {
	int shmid;
	Node *node;

	if ( share->tail == NULL ) {
		/* create a new top segment */

		if ( ( node = _shmseg_alloc( share ) ) == NULL )
			return -1;

		share->head  = node;
		share->tail  = node;
		share->shmid = node->shmid;

	} else if ( ( shmid = share->tail->shmhead->next_shmid ) != -1 ) {
		/* attach an existing linked segment */

		if ( ( node = _shmseg_shmat( shmid ) ) == NULL )
			return -1;

		/* the shmid doesn't point to a sharelite segment */
		if ( node->shmhead->shm_magic != SHARELITE_MAGIC ) {
			_shmseg_shmdt( node );
			errno = EFAULT;
			return -1;
		}

		share->tail->next = node;
		share->tail       = node;

	} else {
		/* create a new linked segment */

		if ( ( node = _shmseg_alloc( share ) ) == NULL )
			return -1;

		share->tail->next = node;
		share->tail       = node;

	}

	return 0;
}


#define _SHMSEG_TRUNC_SETUP_MACRO_	\
	if ( share->tail == last )	\
		return 0;		\
	if ( last == NULL ) {		\
		node = share->head;	\
		share->head = NULL;	\
		share->tail = NULL;	\
	} else {			\
		node = last->next;	\
		share->tail = last;	\
	}

/* nondestructively free stale Node structures   */
int _shmseg_forget( Share *share, Node *last ) {
	Node *node, *next;

	_SHMSEG_TRUNC_SETUP_MACRO_

	while ( node != NULL ) {
		next = node->next;
		if ( _shmseg_shmdt( node ) == -1 )
			return -1;
		node = next;
	}

	return 0;
}

/* remove unneeded segments from the system         */
int _shmseg_remove( Share *share, Node *last ) {
	Node *node, *next;

	_SHMSEG_TRUNC_SETUP_MACRO_

	while ( node != NULL ) {
		next = node->next;
		if ( _shmseg_undef( share, node ) == -1 )
			return -1;
		node = next;
	}

	return 0;
}

