#
# This script is used to run start and stop scripts
# The environment must contain a $CTOOLS_PHASE variable.
#===========================================================================

set -eEuo pipefail +o histexpand
exec 2>&1

if [ -z "${CTOOLS_PHASE:-}" ]; then
  echo "*** CTOOLS_PHASE variable not found ***"
  exit 1
fi

#---------------------------------

function _ctools_run_usage
{
cat <<EOF
Usage: ${CTOOLS_PHASE}-container [-h] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-i] [-f]

-h        : Display this help information
-v        : increase verbose level. Can be set more than once
-c <dir>  : Define config directory (default: /etc/ctools)
-r <role> : Set role (default: none)
-t <dir>  : Define tmp directory.
-i        : Don't run 'init-container' if it was not run already. The default
            behavior allows to run the same image on Kubernetes and
            environments without init containers, like docker-compose.
-f        : Freeze (run an endless loop) on failure . Makes debugging easier
            (create a shell in the container to investigate failure).

All these options can be set on the command line or via environment variables
(refer to the documentation for variable names).
EOF
}

#---------------------------------
# Main

#----
# Get cmd line opts

source _ctools_common_1

while getopts vc:r:t:ifh _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL=`expr $CTOOLS_LOGLEVEL + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    i) CTOOLS_NO_INIT=y ;;
    f) CTOOLS_FAILURE_FREEZE=y ;;
		h) _ctools_run_usage ; exit 0 ;;
		?) _ctools_run_usage ; exit 1 ;;
	esac
done

source _ctools_common_2

#----

_ctools_load_cfg_env

_ctools_load_init_env

#----
# Find script and run it

script="`_ctools_cfg_script_path $CTOOLS_PHASE`"
if [ -n "$CTOOLS_ROLE" ]; then
  rolescript="`_ctools_cfg_script_path role/$CTOOLS_ROLE/$CTOOLS_PHASE`"
  [ -f "$rolescript" ] && script="$rolescript" || :
fi

if [ ! -f "$script" ]; then
  _ctools_msg_error "$CTOOLS_PHASE: Script not found"
  rc=1
else
  source "$script"
fi
