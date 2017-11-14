
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
		set +x
		setsid -c /bin/sh -l 2>&1
		set -x
	)
	rc=$?
	echo
	echo "rescue shell returned $rc"
	echo
	return $rc
}

