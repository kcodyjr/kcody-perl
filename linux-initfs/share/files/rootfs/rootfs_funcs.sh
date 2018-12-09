
findfs_mount_is_valid() {

	if [ ! -x "${FINDFS_MNT}/${ROOTFS_BIN}" ]
	then
		return 1
	fi

	return 0
}

