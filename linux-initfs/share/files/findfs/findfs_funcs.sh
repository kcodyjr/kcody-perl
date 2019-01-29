
findfs_name_to_dev() {
	local shortname="$1"
	local try tmp

	for try in /dev /dev/mapper
	do
		tmp="$try/$shortname"
		if [ -e $tmp ]
		then
			echo "$tmp"
			return 0
		fi
	done

	return 1
}

findfs_is_mounted() {
	grep -q "${FINDFS_MNT-undefined}" /etc/mtab
}

findfs_get_fstype() {
	local device="$1"

	local fstype=$(blkid "$device" | sed 's/.*TYPE=//;s/^"//;s/"$//')

	if [ -z "$fstype" ]
	then
		return 1
	fi

	echo "$fstype"

	return 0
}

findfs_mount_args() {
	local device="$1"

	local fstype="$(findfs_get_fstype "$device")"

	if [ -z "$fstype" ]
	then
		return 1
	fi

	echo -n "-t $fstype "

	echo -n "-o "

	echo -n "$FINDFS_WRI"

	if [ -n "$FINDFS_FLG" ]
	then
		echo -n ",$FINDFS_FLG"
	fi

	if [ -n "$FINDFS_VOL" -a "$fstype" == "btrfs" ]
	then
		echo -n ",subvol=${FINDFS_VOL}"
	fi

	echo

	return 0
}

findfs_try_mount() {
	local device="$1"

	if [ -z "$device" ]
	then
		device="$FINDFS_DEV"
	fi

	if [ -z "$device" ]
	then
		echo BUG: findfs_try_mount got no argument
		return 1
	fi

	local options="$(findfs_mount_args "$device")"

	if [ -z "$options" ]
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

	elif [ -z "$FINDFS_DEV" ]
	then
		FINDFS_DEV="$device"
	fi

	return 0
}

findfs_do_mount() {
	local device="$1"

	if [ -z "$device" ]
	then
		device="$FINDFS_DEV"
	fi

	if [ -z "$device" ]
	then
		echo BUG: findfs_try_mount got no argument
		return 1
	fi

	findfs_try_mount "$device"

	if ! findfs_is_mounted
	then
		local f
		for f in /lib/initfs/load.d/*.sh
		do
			if [ -r "$f" ]
			then
				. $f
			fi
			findfs_is_mounted && break
			findfs_try_mount "$device"
		done
	fi

	return $?
}

findfs_lsblk() {
	IFS=$'\n' LSBLK=($(lsblk -P -o "name,type,size,label,fstype,parttype"))
}

findfs_maybe() {

	if [ -z "$FSTYPE" ]
	then
		return 1
	fi

	local DEVICE

	DEVICE="$(findfs_name_to_dev "$NAME")"

	if ${FINDFS_MAYBE-false}
	then
		return 0
	fi

	echo findfs_do_mount "$DEVICE"
	false
	return $?
}

findfs_locate() {

	findfs_lsblk

	local FINDFS_MAYBE blk

	for FINDFS_MAYBE in $FINDFS_STEPS
	do
		for blk in "${LSBLK[@]}"
		do
			$blk findfs_maybe && return 0
		done
	done

	return 1
}

initfs_main_function() {

	if [ -z "$FINDFS_MNT" ]
	then
		echo BUG: FINDFS_MNT never got defined
		return 1
	fi

	if [ -n "$FINDFS_DEV" ]
	then
		findfs_do_mount
	else
		findfs_locate
	fi

	return $?
}


