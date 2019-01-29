
findfs_mount_is_valid() {

	if [ -n "$ROOTFS_BIN" ]
	then
		if [ -x "${FINDFS_MNT}${ROOTFS_BIN}" ]
		then
			return 0
		fi

	else
		for bin in /sbin/init /etc/init /bin/init /bin/sh
		do
			if [ -x "${FINDFS_MNT}${bin}" ]
			then
				ROOTFS_BIN="$bin"
				return 0
			fi
		done
	fi

	return 1
}

