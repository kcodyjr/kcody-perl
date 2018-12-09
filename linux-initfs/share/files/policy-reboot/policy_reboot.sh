
###############################################################################
# reboot the system if we cannot find the rootfs

FALLBACK_ACTION=fallback_action_reboot

fallback_action_reboot() {

	echo
	echo
	echo '*** FATAL ***'
	echo
	echo 'Unable to locate filesystem'
	echo
	echo 'Rebooting.'
	echo
	echo

	reboot -f

}

