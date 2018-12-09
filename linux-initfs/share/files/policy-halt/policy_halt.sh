
###############################################################################
# halt the system if we cannot find the rootfs

FALLBACK_ACTION="fallback_action_halt"

fallback_action_halt() {

	echo
	echo
	echo '*** FATAL ***'
	echo
	echo 'Unable to locate filesystem'
	echo
	echo 'Halting.'
	echo
	echo

	halt -f

}

