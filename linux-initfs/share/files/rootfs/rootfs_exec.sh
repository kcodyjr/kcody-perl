
doit=nonempty

if [ -z "$FINDFS_MNT" ]
then
	echo BUG: FINDFS_MNT empty in rootfs_exec
	unset doit
fi

if [ -z "$ROOTFS_BIN" ]
then
	echo BUG: ROOTFS_BIN empty in rootfs_exec
	unset doit
fi

if [ -n "$doit" ]
then
	exec chroot "$FINDFS_MNT" "$ROOTFS_BIN"

	echo BUG: returned from exec chroot call
	halt

else
	echo BUG: insufficient parameters in rootfs_exec
	halt
fi

