
/*
 * sharelite_shm.h - part of IPC::Shm::Simple
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


#ifndef __SHARELITE_SHM_H__
#define __SHARELITE_SHM_H__

#include "sharelite.h"


/* --- SHARED SEGMENT LIST FUNCTIONS --- */

/* attach the next segment, creating one if necessary *
 * called when the Node list is too short             */
int _shmseg_append( Share *share );

/* nondestructively free stale Node structures  *
 * called when another process removed segments *
 * or when the whole share is being detached    */
int _shmseg_forget( Share *share, Node *last );

/* remove unneeded segments from the system            *
 * called when a write operation leaves extra segments *
 * or when the whole share is being deallocated        */
int _shmseg_remove( Share *share, Node *last );


#endif /* define __SHARELITE_SHM_H__ */

