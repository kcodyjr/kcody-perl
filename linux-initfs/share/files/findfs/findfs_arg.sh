
get_arg_findfs() {
	local arg="$1"

	case $arg in

		ro)
			FINDFS_WRI=ro
			;;
		rw)
			FINDFS_WRI=rw
			;;

	esac
}

import_handler get_arg_findfs

