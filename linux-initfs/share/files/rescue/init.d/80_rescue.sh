
###############################################################################
# drop to a rescue shell

rescue_shell() {
	local rc
	echo
	echo "RESCUE SHELL: (exit or ^d to continue)"
	echo
	(
		export HOME=/root
		cd /root
		setsid -c /bin/sh -l 2>&1
	)
	rc=$?
	echo
	echo "rescue shell returned $rc"
	echo
	return $rc
}


###############################################################################
# make the user mount the rootfs manually

rootfs_not_found() {

	while [[ 1 ]]
	do
		echo
		echo "Root filesystem not mounted."
		echo "Mount it to /mnt/rootfs manually, then exit this shell."
		echo

		rescue_shell

		if is_rootfs_mounted
		then
			break
		fi

		mount_rootfs

		if is_rootfs_mounted
		then
			break
		fi

	done

	return 0
}

