
###############################################################################
# make the user mount the rootfs manually

ROOTFS_NOT_FOUND=rootfs_not_found_rescue

rootfs_not_found_rescue() {

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

}

