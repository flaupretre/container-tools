# Copyright 2024-2025 - Francois Laupretre <francois@tekwire.net>
#=============================================================================
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (LGPL) as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#=============================================================================
# This script is used to run start and stop scripts
# The environment must contain a $CTOOLS_PHASE variable.
#=============================================================================

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
Usage: ${CTOOLS_PHASE}-container [-h] [-V] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-i] [-f]

-h        : Display this help information
-V        : Display software version and exit
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

while getopts vc:r:t:ifhV _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL=`expr ${CTOOLS_LOGLEVEL:-0} + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    i) CTOOLS_NO_INIT=y ;;
    f) CTOOLS_FAILURE_FREEZE=y ;;
		h) _ctools_run_usage ; exit 0 ;;
    V) echo "@VERSION@"; exit 0 ;;
		?) _ctools_run_usage ; exit 1 ;;
	esac
done

source ctools_env

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
  exit 1
else
  source "$script"
fi
