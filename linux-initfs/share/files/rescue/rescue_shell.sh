
###############################################################################
# drop to a rescue shell

rescue_shell() {
	local rc
	echo
	echo 'RESCUE SHELL: (exit or ^d to continue)'
	echo
	(
		export HOME=/root
		cd $HOME
		set +x
		echo "+ setsid -c /bin/sh -l" >&2 # force trace entry
		setsid -c /bin/sh -l </dev/console >/dev/console 2>&1
	)
	rc=$?
	echo
	echo 'rescue shell returned' "$rc"
	echo
	return $rc
}

