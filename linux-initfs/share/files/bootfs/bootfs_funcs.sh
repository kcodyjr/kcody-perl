
findfs_mount_is_valid() {

	if [ -d "${FINDFS_MNT}/loader" ]
	then
		BOOTFS_TOP="${FINDFS_MNT}/loader"
		return 0
	fi

	if [ -d "${FINDFS_MNT}/boot/loader" ]
	then
		BOOTFS_TOP="${FINDFS_MNT}/boot/loader"
		return 0
	fi

	return 1
}

