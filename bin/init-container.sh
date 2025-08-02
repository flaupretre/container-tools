#
#===========================================================================

set -eEuo pipefail
exec 2>&1

#---------------------------------

function _ctools_init_usage
{
cat <<EOF
Usage: ${CTOOLS_PHASE}-container [h] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-f]

-h        : Display this help information
-v        : increase verbose level. Can be set more than once
-c <dir>  : Define config directory (default: /etc/ctools)
-r <role> : Set role (default: none)
-t <dir>  : Define tmp directory. Created if it does not exist yet. File
            system must be writable (default: '/tmp/ctools')
-f        : Freeze (run an endless loop) on failure . Makes debugging easier
            (create a shell in the container to investigate failure).

All these options can be set on the command line or via environment variables
(refer to the documentation for variable names).
EOF
}

#---------------------------------
# Main

CTOOLS_PHASE="init"

#----
# Get cmd line opts

source _ctools_common_1

while getopts vc:r:t:fh _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL=`expr $CTOOLS_LOGLEVEL + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    f) CTOOLS_FREEZE_ON_FAILURE=y ;;
		h) _ctools_init_usage ; exit 0 ;;
		?) _ctools_init_usage ; exit 1 ;;
	esac
done

source _ctools_common_2

#----

_ctools_init_create_envfile

CTOOLS_INIT_SCRIPTS=""

_ctools_load_cfg_env

for script in $CTOOLS_INIT_SCRIPTS; do
  _ctools_msg_separator
  echo "Executing init script: $script"
  echo
  echo "#--- Script: $script" >$CTOOLS_INIT_ENVFILE
  source "`_ctools_cfg_script_path init-scripts/$script`"
done

echo "------------- Init end ------------"
_ctools_init_debug_dump_envfile
