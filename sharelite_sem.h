
/*
 * sharelite_sem.h - part of IPC::Shm::Simple
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


#ifndef __SHARELITE_SEM_H__
#define __SHARELITE_SEM_H__

#include <sys/ipc.h>
#include <sys/sem.h>
#include <errno.h>

#include "sharelite.h"


/* --- DEFINE MACROS FOR SEMAPHORE OPERATIONS --- */

#define GET_EX_LOCK(A)     semop((A)->semid, &ex_lock[0],    3)
#define GET_EX_LOCK_NB(A)  semop((A)->semid, &ex_lock_nb[0], 3)
#define REL_EX_LOCK(A)     semop((A)->semid, &ex_unlock[0],  1)
#define GET_SH_LOCK(A)     semop((A)->semid, &sh_lock[0],    2)
#define GET_SH_LOCK_NB(A)  semop((A)->semid, &sh_lock_nb[0], 2)
#define REL_SH_LOCK(A)     semop((A)->semid, &sh_unlock[0],  1) 


/* --- DEFINE STRUCTURES FOR MANIPULATING SEMAPHORES --- */

static struct sembuf ex_lock[3] = {
  { 0, 0, 0 },        /* wait for readers to finish */
  { 1, 0, 0 },        /* wait for writers to finish */
  { 1, 1, SEM_UNDO }  /* assert write lock */
};

static struct sembuf ex_lock_nb[3] = {
  { 0, 0, IPC_NOWAIT },             /* wait for readers to finish */
  { 1, 0, IPC_NOWAIT },             /* wait for writers to finish */
  { 1, 1, (SEM_UNDO | IPC_NOWAIT) } /* assert write lock */     
};

static struct sembuf ex_unlock[1] = {
  { 1, -1, (SEM_UNDO | IPC_NOWAIT) } /* remove write lock */
};

static struct sembuf sh_lock[2] = {
  { 1, 0, 0 },        /* wait for writers to finish */
  { 0, 1, SEM_UNDO }  /* assert shared read lock */
};

static struct sembuf sh_lock_nb[2] = {
  { 1, 0, IPC_NOWAIT },             /* wait for writers to finish */
  { 0, 1, (SEM_UNDO | IPC_NOWAIT) } /* assert shared read lock */
};                
static struct sembuf sh_unlock[1] = {
  { 1, -1, (SEM_UNDO | IPC_NOWAIT) } /* remove shared read lock */
};                                 


/* --- SEMAPHORE CREATE/REMOVE FUNCTIONS --- */

/* create and exclusively lock a new semaphore, and return its semid */
inline
int _sharelite_sem_create( Share *share, int flags ) {

again:
	if ( share->semid = semget( IPC_PRIVATE, 2,
				flags | IPC_CREAT | IPC_EXCL ) < 0 )
		return -errno;

	/* another process could remove our new semaphore before we lock it */
	if ( GET_EX_LOCK( share ) < 0 ) {
		if ( errno == EINVAL )
			goto again;
		return -errno;
	}

	return share->semid;
}

/* remove a semaphore from the system, any further ops to return -EIDRM */
inline
int _sharelite_sem_remove( int semid ) {

	if ( semctl( semid, 0, IPC_RMID ) < 0 )
		return -errno;

	return 0;
}


#endif /* define __SHARELITE_SEM_H__ */

