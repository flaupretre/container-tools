#
#===========================================================================

set -eEuo pipefail
exec 2>&1

#---------------------------------

function _ctools_start_usage
{
cat <<EOF
Usage: start-container [-h] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-e] [-i] [-f]

-h        : Display this help information
-v        : increase verbose level. Can be set more than once
-c <dir>  : Define config directory (default: /etc/ctools)
-r <role> : Set role (default: none)
-t <dir>  : Define tmp directory. Created if it does not exist yet. File
            system must be writable.
-e        : Ensure this command won't exit (run an endless loop if start
            script returns). Used mostly for debugging.
-i        : Run 'init-container' if it was not run already. It allows to run
            the same image on Kubernetes and environments without init
            containers, like docker-compose.
-f        : Freeze (run an endless loop) on failure . Makes debugging easier
            (you can create a shell in the container to investigate failure).

All these options can be set on the command line or via environment variables
(refer to the documentation for variable names).
EOF
}

#---------------------------------
# Main

CTOOLS_LOGLEVEL="${CTOOLS_LOGLEVEL:-0}"
export CTOOLS_PHASE="start"
CTOOLS_START_NOEXIT=""
CTOOLS_ENSURE_INIT=""

#----
# Get cmd line opts


while getopts vc:r:t:eifh _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL=`expr $CTOOLS_LOGLEVEL + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    e) CTOOLS_START_NOEXIT=y ;;
    i) CTOOLS_ENSURE_INIT=y ;;
    f) CTOOLS_FREEZE_ON_FAILURE=y ;;
		h) _ctools_start_usage ; exit 0 ;;
		?) _ctools_usage ; exit 1 ;;
	esac
done

#----

. ctools-common

_ctools_load_cfg_env

_ctools_load_init_env

#----
# Actual start

startscript="`_ctools_cfg_script_path start`"
if [ -n "$CTOOLS_ROLE" ]; then
  rolescript="`_ctools_cfg_script_path role/$CTOOLS_ROLE/start`"
  [ -f "$rolescript" ] && startscript="$rolescript" || :
fi

if [ ! -f "$startscript" ]; then
  _ctools_msg_error "$startscript: Start script not found"
  _ctools_freeze
fi

rc=0
bash "$startscript" || rc=$?
if [ "$rc" != 0 ]; then
  _ctools_msg_error "Start script returned a non-zero exit code ($rc)"
fi  

if [ -n "$CTOOLS_START_NOEXIT" ]; then
  _ctools_freeze
fi
