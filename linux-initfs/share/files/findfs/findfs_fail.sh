
if ! findfs_is_mounted
then

	if [ -n "$FALLBACK_ACTION" ]
	then
		$FALLBACK_ACTION
	else
		echo 'BUG: do not have a failure handler'
	fi

fi

if ! findfs_is_mounted
then
	exit # panic
fi

