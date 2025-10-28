
if [ -z $INITFS_DIR ]
then
	INITFS_DIR='/mnt/initfs'
fi

INITFS_MNT="${FINDFS_MNT}${INITFS_DIR}"

if [ -d "$INITFS_MNT" ]
then
	mount -o mode=750 -t tmpfs tmpfs "$INITFS_MNT"

	if [ ! -d "$INITFS_DIR" ]
	then
		mkdir "$INITFS_DIR"
	fi

	mount -o bind / "$INITFS_DIR"

	cp -a "$INITFS_DIR/"* "$INITFS_MNT"

	exec 2> /dev/null
	cp -a "/run/initfs.trc" "${INITFS_MNT}/run"
	exec 2>> "${INITFS_MNT}/run/initfs.trc"

	umount "$INITFS_DIR"

fi

