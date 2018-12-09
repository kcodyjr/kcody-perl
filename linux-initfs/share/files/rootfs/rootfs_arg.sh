
get_arg_rootfs() {
	local arg="$1"

	case $arg in

		root=*)
			FINDFS_DEV=${arg#root=}
			;;

		rootflags=*)
			FINDFS_FLG=${arg#rootflags=}
			;;

		init=*)
			ROOTFS_BIN=${arg#init=}
			;;

	esac
}

import_handler get_arg_rootfs

