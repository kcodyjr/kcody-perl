
/*
 * sharelite.h - part of IPC::Shm::Simple
 *
 * Originally part of IPC::ShareLite by Maurice Aubrey.
 *
 * Adapted 2/2005 by K Cody <kcody@jilcraft.com>
 *
 * This code may be modified or redistributed under the terms
 * of either the Artistic or GNU General Public licenses, at
 * the modifier or redistributor's discretion.
 *
 */


#ifndef __SHARELITE_H__
#define __SHARELITE_H__

/* Default shared memory segment size.  Each segment is the *
 * same size.  Maximum size is system-dependent (SHMMAX).   *
 * CHANGED 2/2005 by K Cody <kcody@jilcraft.com>            *
 * seems this should probably track system page size        *
 * also, now chunk segments can be of different size        *
 * SEG_SIZE is the default, applies when size < MIN_SIZE    */
#define SHARELITE_SEG_SIZE 4096
#define SHARELITE_MIN_SIZE  256

/* Magic value for detecting whether sharelite.c created the segment * 
 * ADDED 2/2005 by K Cody <kcody@jilcraft.com>                       */
#define SHARELITE_MAGIC 0x4C524550  /* 'PERL' */

/* Lock constants used internally by us.  They happen to be the same *
 * as for flock(), but that's purely coincidental                    *
 * CHANGED 2/2005 by K Cody <kcody@jilcraft.com>                     *
 * Lock constants are now imported from <sys/file.h>                 *
 * internal implementation doesn't care, but interface standards do  */

/* Structure at the top of every shared memory segment. *
 * next_shmid is used to construct a linked-list of     *
 * segments.  length is unused, except for the first    *
 * segment.                                             * 
 * REVAMPED 2/7/2005 by K Cody <kcody@jilcraft.com>     *
 * length and version moved to top segment Descriptor   */
typedef struct {
  unsigned int	 shm_magic;
  int		 next_shmid;
} Header;

/* Structure just under the top of the first linked segment  *
 * ADDED 2/2005 by K Cody <kcody@jilcraft.com>               */
typedef struct {
  int		 seg_semid;    /* segment lock semaphore     */
  int		 seg_perms;    /* segment creation flags     */
  int		 data_serial;  /* incremented on write       */
  unsigned int	 data_length;  /* total data in all chunks   */
  unsigned int	 data_chunks;  /* number of chunk segments   */
  unsigned int	 size_topseg;  /* total size of main segment */
  unsigned int	 size_chunkseg;/* total size of appended seg */
} Descriptor;

/* Structure for the per-process segment list.  This list    *
 * is similar to the shared memory linked-list, but contains *
 * the actual shared memory addresses returned from the      *
 * shmat() calls.  Since the addresses are mapped into each  *
 * process's data segment, we cannot make them global.       *
 * This linked-list may be shorter than the shared memory    *
 * linked-list -- nodes are added on to this list on an      *
 * as-needed basis                                           *
 * REVAMPED 2/2005 by K Cody <kcody@jilcraft.com>            *
 * NOTE: Might also be -longer- than the shared memory list  */
typedef struct node {
  int		 shmid;		/* doublecheck freshness of this list   */
  char		*shmdata;	/* pointer to shared data storage area  */
  Header	*shmhead;	/* pointer to shared segment header     */
  Descriptor	*shminfo;	/* pointer to Descriptor in top shmseg  */
  struct node	*next;		/* private memory pointer to next Node  */
} Node;

/* The primary structure for this library.  We pass this back *
 * and forth to perl                                          *
 * REVAMPED 2/2005 by K Cody <kcody@jilcraft.com>             */
typedef struct {
  key_t         key;		/* ipckey requested at instantiation    */
  int           semid;		/* semid of assosciated lock semaphore  */
  int           shmid;		/* shmid of top shared memory segment   */
  int           flags;		/* mode and perms set at instantiation  */
  int           size_data;	/* available data size in top shmseg    */
  short		remove;		/* asserts remove segment on detach     */
  short         lock;		/* current semaphore lock status        */
  Node         *head;		/* first attached segment pointer       */
  Node         *tail;		/* last attached segment pointer        */
} Share;                

/* prototypes */
/* REVAMPED 2/2005 by K Cody <kcody@jilcraft.com> */

/* attach to a segment by its shmid */
Share	*sharelite_shmat(int shmid);
/* attach to a segment by its ipckey, if it exists */
Share	*sharelite_attach(key_t key);
/* create a new segment by its ipckey, if one doesn't exist */
Share	*sharelite_create(key_t key, int segsize, int flags);

/* detach from the segment nondestructively */
int	 sharelite_shmdt(Share *share);
/* detach from the segment and remove it from the system */
int	 sharelite_remove(Share *share);

/* change the locking status of the semaphore */
int	 sharelite_lock(Share *share, int flags); 
/* check the locking status of the semaphore  */
int	 sharelite_locked(Share *share, int flags);

/* store a block of raw binary data */
int	 sharelite_store(Share *share, char *data, int length);
/* fetch back a block of raw binary data */
int	 sharelite_fetch(Share *share, char **data);

/* report the ipckey of the top segment */
int      sharelite_key(Share *share);
/* report the shmid of the top segment */
int      sharelite_shmid(Share *share);
/* report the total bytes currently stored */
int	 sharelite_length(Share *share);
/* report the serial number stored in the top segment Descriptor */
int	 sharelite_serial(Share *share);
/* report or set the size of any subsequent chunk segments */
int	 sharelite_segsize(Share *share, int size);
/* report the number of operating system segments in use */
int	 sharelite_nsegments(Share *share);

#endif /* define __SHARELITE_H__ */
