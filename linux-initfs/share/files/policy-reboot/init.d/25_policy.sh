
###############################################################################
# reboot the system if we cannot find the rootfs

ROOTFS_NOT_FOUND=rootfs_not_found_reboot

rootfs_not_found_reboot() {

	echo
	echo
	echo '*** FATAL ***'
	echo
	echo 'Unable to locate root filesystem.'
	echo 'Rebooting system.'
	echo
	echo

	reboot -f

}

