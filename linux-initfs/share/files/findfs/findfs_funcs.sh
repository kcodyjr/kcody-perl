
findfs_is_mounted() {
	grep -q ${FINDFS_MNT-undefined} /etc/mtab
}

findfs_get_fstype() {
	local device="$1"

	local fstype=$(blkid "$device" | sed 's/.*TYPE=//;s/^"//;s/"$//')

	if [ -z $fstype ]
	then
		return 1
	fi

	echo "$fstype"

	return 0
}

findfs_mount_args() {
	local device="$1"

	local fstype="$(findfs_get_fstype)"

	if [ -z $fstype ]
	then
		return 1
	fi

	echo -n "-t $fstype "

	echo -n "$FINDFS_WRI"

	if [ -n "$FINDFS_FLG" ]
	then
		echo -n ",$FINDFS_FLG"
	fi

	echo

	return 0
}

findfs_try_mount() {
	local device="$1"

	if [ -z $device ]
	then
		device="$FINDFS_DEV"
	fi

	if [ -z $device ]
	then
		echo BUG: findfs_try_mount got no argument
		return 1
	fi

	local options="$(findfs_mount_args "$device")"

	if [ -z $options ]
	then
		return 1
	fi

	mount $options "$device" "$FINDFS_MNT"

	if [ $? -ne 0 ]
	then
		return 1
	fi

	if ! findfs_mount_is_valid
	then
		umount "$FINDFS_MNT"
		return 1

	elif [ -z $FINDFS_DEV ]
	then
		FINDFS_DEV="$device"
	fi

	return 0
}

findfs_do_mount() {

	findfs_try_mount

	if ! findfs_is_mounted
	then
		local f
		for f in /lib/initfs/load.d/*.sh
		do
			if [ -r $f ]
			then
				. $f
			fi
			findfs_is_mounted && break
			findfs_try_mount
		done
	fi

	return $?
}

initfs_main_function() {

	if [ -z $FINDFS_MNT ]
	then
		echo BUG: FINDFS_MNT never got defined
		return 1
	fi

	if [ -n $FINDFS_DEV ]
	then
		findfs_do_mount
	else
		findfs_locate
	fi

	return $?
}


