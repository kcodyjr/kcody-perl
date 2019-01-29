
INITFS_MNT="${FINDFS_MNT}/mnt/initfs"

if [ -d "$INITFS_MNT" ]
then
	mount -o bind / "$INITFS_MNT"
	chmod 750 "$INITFS_MNT"
	mount -o ro,remount "$INITFS_MNT"
fi

