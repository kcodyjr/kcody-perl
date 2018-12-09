
###############################################################################
# make the user mount the rootfs manually

FALLBACK_ACTION="fallback_action_rescue"

fallback_action_rescue() {

	while true
	do
		echo
		echo
		echo '*** ERROR ***'
		echo
		echo 'Filesystem not found.'
		echo
		echo 'Mount it manually, then exit this shell.'
		echo

		rescue_shell

		if findfs_is_mounted
		then
			break
		fi

		findfs_try_mount

		if findfs_is_mounted
		then
			break
		fi

	done

}

