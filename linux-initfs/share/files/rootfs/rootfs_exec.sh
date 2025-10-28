
doit=nonempty

if [ -z "$ROOTFS_BIN" ]
then
	findfs_mount_is_valid
fi

if [ -z "$ROOTFS_BIN" ]
then
	echo BUG: ROOTFS_BIN empty in rootfs_exec
	unset doit
fi

if [ -z "$FINDFS_MNT" ]
then
	echo BUG: FINDFS_MNT empty in rootfs_exec
	unset doit
fi

if [ -z "$doit" ]
then
	echo BUG: insufficient parameters in rootfs_exec

else
	exec switch_root -c /dev/console "$FINDFS_MNT" "$ROOTFS_BIN"
	echo SEVERE: returned from "exec switch_root '$FINDFS_MNT' '$ROOTFS_BIN'" >&2
fi

