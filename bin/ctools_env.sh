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
# This script is run after cmd line opts are parsed, so that variables have
# their final values
#=============================================================================

function _ctools_cfg_script_path
{
echo "$CTOOLS_CFGDIR/$1.sh"
}

#----

function _ctools_source_cfg_script
{
local file ignore name scripts script

ignore=
if [ "X$1" = "X-i" ]; then
  ignore=y
  shift
fi

name="$1"

scripts="$name ${CTOOLS_PHASE}-$name"
[ -n "$CTOOLS_ROLE" ] && scripts="$scripts role/$CTOOLS_ROLE/$name role/$CTOOLS_ROLE/${CTOOLS_PHASE}-$name" || :

for script in $scripts; do
  file="`_ctools_cfg_script_path $script`"
  if [ -f "$file" ]; then
    _ctools_msg_trace "Sourcing file: $file"
    source "$file"
  else
    if [ -n "$ignore" ]; then
      _ctools_msg_trace "$file: file not found (ignoring)"
    else
      _ctools_msg_error "$file: file not found"
      return 1
    fi
  fi
done
}

#----

function _ctools_init_create_envfile
{
rm -f "$CTOOLS_INIT_ENVFILE"
touch "$CTOOLS_INIT_ENVFILE"
}

#----

function _ctools_init_debug_dump_envfile
{
if [ "$CTOOLS_LOGLEVEL" -ge 2 ]; then
  echo "Content of init environment file :"
  _ctools_msg_separator
  cat $CTOOLS_INIT_ENVFILE
  _ctools_msg_separator
fi
}

#----

function ctools_save_var
{
local var value

for var; do
  value="${!var}"
  (
  echo -n "export $var=\""
  echo -n "$value" | sed -e 's,\\,\\\\,g' -e 's,",\\",g' -e 's,\$,\\\$,g' -e 's,`,\\`,g'
  echo "\""
  ) >>"$CTOOLS_INIT_ENVFILE"
done
}

#----
# Load environment variables saved by init scripts.
# If init has not run and $CTOOLS_NO_INIT is not set, run it.

function _ctools_load_init_env
{
local env1 env2

if [ ! -f "$CTOOLS_INIT_ENVFILE" ]; then
  _ctools_msg_trace "Seems init was not run yet"
  if [ -z "$CTOOLS_NO_INIT" ]; then
    echo "Running init because it was not run yet"
    init-container
  else
    echo "Init won't run because it was explicitely disabled"
  fi
fi

env1="$(env | sort)"
if [ -f "$CTOOLS_INIT_ENVFILE" ]; then
  _ctools_msg_trace "Loading init environment from $CTOOLS_INIT_ENVFILE"
  source "$CTOOLS_INIT_ENVFILE"
else
  _ctools_msg_trace "Init env file ($CTOOLS_INIT_ENVFILE) not found"
fi

if [ "$CTOOLS_LOGLEVEL" -ge 2 ]; then
  echo "Differences in environment after loading init env :"
  _ctools_msg_separator
  diff <( echo "$env1" ) <( env | sort ) || :
  _ctools_msg_separator
fi
}

#----

function _ctools_load_cfg_env
{
_ctools_source_cfg_script -i "env"
}

#----

function  _ctools_freeze
{
_ctools_msg_separator
echo "Going to sleep forever..."

touch $CTOOLS_FROZEN
sleep infinity
}

#----

function  ctools_is_frozen
{
[ -f "$CTOOLS_FROZEN" ]
}

#----

function _ctools_backtrace {
local deptn=${#FUNCNAME[@]}

for ((i=1; i<$deptn; i++)); do
  local func="${FUNCNAME[$i]}"
  local line="${BASH_LINENO[$((i-1))]}"
  local src="${BASH_SOURCE[$((i-1))]}"
  printf '%*s' $i '' # indent
  echo "at: $func(), $src, line $line"
done
}

function _ctools_failure_handler
{
local rc line file

set +vx
_ctools_msg_error "Script failure (rc=$1)"
_ctools_backtrace

if [ -n "$CTOOLS_FAILURE_FREEZE" ]; then
  _ctools_freeze
fi
}

#----

function _ctools_msg_trace
{
[ "$CTOOLS_LOGLEVEL" -ge 1 ] && echo ">>> $*" || :
}

#----

function _ctools_msg_debug
{
[ "$CTOOLS_LOGLEVEL" -ge 2 ] && echo "D>> $*" || :
}

#----

function _ctools_msg_error
{
echo "*** ERROR: $*"
}

#----

function _ctools_fatal
{
_ctools_msg_error "$* - Aborting execution"
exit 1
}

#----

function _ctools_msg_separator
{
echo "-------------------------------------------------"
}

#---------------------------------------
# Main

export CTOOLS_LOGLEVEL="${CTOOLS_LOGLEVEL:-0}"
export CTOOLS_ROLE="${CTOOLS_ROLE:-}"
export CTOOLS_CFGDIR="${CTOOLS_CFGDIR:-/etc/ctools}"
export CTOOLS_TMPDIR="${CTOOLS_TMPDIR:-/tmp/ctools}"
export CTOOLS_FAILURE_FREEZE="${CTOOLS_FAILURE_FREEZE:-}"
export CTOOLS_NO_INIT="${CTOOLS_NO_INIT:-}"

#----

[ -d $CTOOLS_TMPDIR ] || mkdir -p $CTOOLS_TMPDIR

if [ ! -d "$CTOOLS_CFGDIR" ]; then
  _ctools_msg_trace "$CTOOLS_CFGDIR: Config dir does not exist"
fi

CTOOLS_INIT_ENVFILE="$CTOOLS_TMPDIR/envfile.sh"
_ctools_msg_debug "Init environment file: $CTOOLS_INIT_ENVFILE"

CTOOLS_FROZEN="$CTOOLS_TMPDIR/frozen"

trap '_ctools_failure_handler $?' ERR
