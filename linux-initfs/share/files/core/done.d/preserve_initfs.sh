
if [ -d ${FINDFS_MNT}/mnt/initfs ]
then
	mount -o bind / ${FINDFS_MNT}/mnt/initfs
	mount -o ro,remount ${FINDFS_MNT}/mnt/initfs
fi

