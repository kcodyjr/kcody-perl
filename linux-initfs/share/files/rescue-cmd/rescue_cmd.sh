
unset rescue_doit

if findfs_is_mounted
then
	rescue_doit=$RESCUE

elif [ -n "$RESCUE" ]
then
	if [ "$ROOTFS_NOT_FOUND" != rootfs_not_found_rescue ]
	then
		rescue_doit=nonempty
	fi
fi

if [ -n "$rescue_doit" ]
then
	rescue_shell
fi

unset rescue_doit

