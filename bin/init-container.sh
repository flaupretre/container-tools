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

set -eEuo pipefail +o histexpand
exec 2>&1

#---------------------------------

function _ctools_init_usage
{
cat <<EOF
Usage: ${CTOOLS_PHASE}-container [h] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-f]

-h        : Display this help information
-V        : Display software version and exit
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

while getopts vc:r:t:fhV _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL=`expr ${CTOOLS_LOGLEVEL:-0} + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    f) CTOOLS_FREEZE_ON_FAILURE=y ;;
    V) echo "@VERSION@"; exit 0 ;;
		h) _ctools_init_usage ; exit 0 ;;
		?) _ctools_init_usage ; exit 1 ;;
	esac
done

source ctools_env

#----

_ctools_init_create_envfile

CTOOLS_INIT_SCRIPTS=""

_ctools_load_cfg_env

if [ -z "$CTOOLS_INIT_SCRIPTS" ]; then
  # Take files in 'init-scripts' dir in alpha order
  for f in `ls -1 $CTOOLS_CFGDIR/init-scripts/*.sh 2>/dev/null`; do
    [ -f "$f" ] && CTOOLS_INIT_SCRIPTS="$CTOOLS_INIT_SCRIPTS `basename $f .sh`" || :
  done
  _ctools_msg_trace "Got init scripts from dir content : $CTOOLS_INIT_SCRIPTS"
fi

if [ -z "$CTOOLS_INIT_SCRIPTS" ]; then
  echo "No init script to run"
else
  for script in $CTOOLS_INIT_SCRIPTS; do
    _ctools_msg_separator
    echo "Executing init script: $script"
    echo >>$CTOOLS_INIT_ENVFILE
    echo "#>>>----- Starting script: $script" >>$CTOOLS_INIT_ENVFILE
    source "`_ctools_cfg_script_path init-scripts/$script`"
    echo >>$CTOOLS_INIT_ENVFILE  # Force newline
    echo "#<<<----- Ending script: $script" >>$CTOOLS_INIT_ENVFILE
  done
fi

echo "------------- Init end ------------"
_ctools_init_debug_dump_envfile
