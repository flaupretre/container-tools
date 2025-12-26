#!/bin/bash
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

set -eEuo pipefail
exec 2>&1

#----

function _ctools_init
{
_ctools_ensure_cfgdir_exists

_ctools_unfreeze
_ctools_unmark_stopping

_ctools_init_create_envfile

_ctools_run_scripts init

#--- Debug dump envfile

if [ "$CTOOLS_LOGLEVEL" -ge 2 ]; then
  echo "Content of init environment file :"
  _ctools_msg_separator
  cat "$CTOOLS_INIT_ENVFILE"
  _ctools_msg_separator
fi
}

#----

function _ctools_start
{
_ctools_ensure_cfgdir_exists

_ctools_unfreeze
_ctools_unmark_stopping

_ctools_load_init_env

_ctools_run_scripts start
}

#----

function _ctools_stop
{
_ctools_ensure_cfgdir_exists

_ctools_mark_stopping

CTOOLS_NO_INIT=y _ctools_load_init_env

_ctools_run_scripts stop
}

#----

function _ctools_run_scripts
{
local phase phdir sc1 scripts path bname dname

phase="$1"
phdir="$CTOOLS_CFGDIR/$phase"
sc1="$(ls -1 $phdir/_common/* 2>/dev/null || :)"
if [ -n "$CTOOLS_ROLE" ]; then
  sc1="$sc1 $(ls -1 $phdir/$CTOOLS_ROLE/* 2>/dev/null || :)"
fi
scripts=""
for path in $sc1; do
  [ -x "$path" ] && scripts="$scripts $path"
done
if [ -z "$scripts" ]; then
  echo "Found no script to run"
else
  for path in $scripts; do
    echo "$(basename "$path") $path"
  done | sort | while read -r bname fullpath; do
    _ctools_msg_separator
    echo "Executing : $fullpath"
    [ "$phase" = init ] && ( echo ; echo "#>>>----- Starting: $fullpath") >>"$CTOOLS_INIT_ENVFILE" || :
    [ -z "$CTOOLS_DRY_RUN" ] && $fullpath || :
    [ "$phase" = init ] && ( echo ; echo "#>>>----- Ending: $fullpath") >>"$CTOOLS_INIT_ENVFILE" || :
  done
fi
}

#----

function _ctools_config_list
{
local phases phase phdir roles role rdir scripts file

phases="$*"
[ -n "$phases" ] || phases="init start stop"

for phase in $phases; do
  echo
  echo "Phase: $phase:"
  phdir="$CTOOLS_CFGDIR/$phase"
  if [ -n "$CTOOLS_ROLE" ]; then
    roles="$CTOOLS_ROLE"
  else
    roles=""
    for dir in "$phdir"/*; do
      [ -d "$dir" ] && roles="$roles $(basename "$dir")" || :
    done
  fi
  if [ -z "$roles" ]; then
    echo "  [No role defined for this phase]"
  else
    for role in $roles; do
      echo "  Role: $role"
      rdir="$phdir/$role"
      scripts=""
      for file in "$rdir"/*; do
        [ -x "$file" ] && scripts="$scripts $(basename "$file")"
      done
      if [ -z "$scripts" ]; then
        echo "    [No script defined for this role]"
      else
        for file in $scripts; do
          echo "    - $file"
        done
      fi
    done
  fi
done
}

#----

function _ctools_config_clear
{
rm -rf "$CTOOLS_CFGDIR"
mkdir -p "$CTOOLS_CFGDIR"
}

#----

function _ctools_config_add
{
local phdir phase role rdir base max rank script prefix target

[ $# = 0 ] && _ctools_fatal "Usage: config add {init|start|stop} <script1 script2...>" || :

phase="$1"
shift
echo "$phase" | grep "init\|start\|stop" >/dev/null \
  || _ctools_fatal "$phase: should be one of init, start, stop"

phdir="$CTOOLS_CFGDIR/$phase"
[ -d "$phdir" ] || mkdir -p "$phdir"

role="${CTOOLS_ROLE:-_common}"
rdir="$phdir/$role"
[ -d "$rdir" ] || mkdir -p "$rdir"

# If rank base not provided, compute max rank

if [ -n "$CTOOLS_RANK_BASE" ]; then
  base="$CTOOLS_RANK_BASE"
else
  max="$(ls -1 "$rdir" | tail -1 | sed 's/^\(...\).*$/\1/')"
  if [ -z "$max" ]; then
    [ "$role" = "_common" ] && base="100" || base="500"
  else
    base=$((max + CTOOLS_RANK_STEP))
  fi
fi

rank="$((1000 + base))"
for script; do
  [ -f "$script" ] || _ctools_fatal "$script: file not found or is not a regular file"
  fname="$(basename "$script")"
  hasprefix=""
  echo "$fname" | grep "^[0-9][0-9][0-9]_" >/dev/null && hasprefix=y || :
  if [ -z "$hasprefix" ]; then
    fname="$(echo "$rank" | sed 's/^.//')_$fname"
    rank="$((rank + CTOOLS_RANK_STEP))"
  fi
  target="$rdir/$fname"
  cp "$script" "$target"
  chmod +x "$target"
  echo "Added script: $target"
done
}

#----

function _ctools_config_del
{
local phdir phase role rdir base max rank script prefix target

[ $# = 0 ] && _ctools_fatal "Usage: config del {init|start|stop} <script1 script2...>" || :

phase="$1"
shift

phdir="$CTOOLS_CFGDIR/$phase"

if [ -d "$phdir" ]; then
  role="${CTOOLS_ROLE:-_common}"
  rdir="$phdir/$role"
  if [ -d "$rdir" ]; then
    for script; do
      if [ "$script" = "all" ]; then
        files="$(ls -1 $rdir/* 2>/dev/null || :)"
      else
        files="$(ls -1 $rdir/???_$script 2>/dev/null || :)"
      fi
      for file in $files; do
        echo "$file: deleting script"
        rm -f "$file"
      done
    done
  fi
fi
}

#----

function _ctools_config
{
local action

[ -d "$CTOOLS_CFGDIR" ] || mkdir -p "$CTOOLS_CFGDIR"

[ $# = 0 ] && _ctools_fatal "Usage: config {add|del|list|clear} [args...]" || :

action="$1"
shift 1

"_ctools_config_$action" "$@"
}

#----

function _ctools_init_create_envfile
{
rm -f "$CTOOLS_INIT_ENVFILE"
touch "$CTOOLS_INIT_ENVFILE"
}

#----

function _ctools_save
{
local var value

[ $# -lt 2 ] && _ctools_fatal "Usage: ctools save <var> <value>" || :

var="$1"
shift
value="$*"

echo "Saving var: $var"
(
echo -n "export $var=\""
echo -n "$value" | sed -e 's,\\,\\\\,g' -e 's,",\\",g' -e 's,\$,\\\$,g' -e 's,`,\\`,g'
echo "\""
) >>"$CTOOLS_INIT_ENVFILE"
}

#----
# Load environment variables saved by init scripts.
# If init has not run and $CTOOLS_NO_INIT is not set, run it.

function _ctools_load_init_env
{
local env1

if [ ! -f "$CTOOLS_INIT_ENVFILE" ]; then
  _ctools_msg_trace "Seems init was not run yet"
  if [ -z "$CTOOLS_NO_INIT" ]; then
    echo "Running init because it was not run yet"
    ctools init
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

function  _ctools_freeze
{
_ctools_msg_separator
echo "Going to sleep forever..."

touch "$CTOOLS_IS_FROZEN"
sleep infinity
}

#----

function  _ctools_unfreeze
{
rm -rf "$CTOOLS_IS_FROZEN"
}

#----

function  ctools_is_frozen
{
[ -f "$CTOOLS_IS_FROZEN" ]
}

#----

function  _ctools_mark_stopping
{
touch "$CTOOLS_IS_STOPPING"
}

#----

function  _ctools_unfreeze
{
rm -rf "$CTOOLS_IS_STOPPING"
}

#----

function  _ctools_is_stopping
{
[ -f "$CTOOLS_IS_STOPPING" ]
}

#----

function _ctools_backtrace {
local deptn=${#FUNCNAME[@]}

for ((i=1; i<deptn; i++)); do
  local func="${FUNCNAME[$i]}"
  local line="${BASH_LINENO[$((i-1))]}"
  local src="${BASH_SOURCE[$((i-1))]}"
  printf '%*s' "$i" '' # indent
  echo "at: $func(), $src, line $line"
done
}

function _ctools_failure_handler
{
local line file

set +vx
_ctools_msg_error "Script failure (rc=$1)"
_ctools_backtrace

if [ -n "$CTOOLS_FAILURE_FREEZE" ]; then
  _ctools_freeze
fi
}

#----

function _ctools_ensure_cfgdir_exists
{
[ -d "$CTOOLS_CFGDIR" ] || _ctools_fatal "$CTOOLS_CFGDIR: Config dir does not exist"
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

#----

function _ctools_run_usage
{
cat <<EOF
Usage: ctools [-h] [-V] [-v] [-c <dir>] [-r <role>] [-t <dir>] [-n] [-b <num>] [-s <num>] [-i] [-f] <cmd> [args...]

-h        : Display this help information
-b        : set base rank (config only)
-s        : set rank step (config only) - default: 10
-V        : Display software version and exit
-v        : increase verbose level. Can be set more than once
-c <dir>  : Define config directory (default: /etc/ctools)
-r <role> : Set a role
-t <dir>  : Define tmp directory.
-n        : Dry run
-i        : The default behavior is to run init during start if it was not run
            previously. This flag disables this.
-f        : Freeze (run an endless loop) on failure . Makes debugging easier
            (you can then create a shell in the container to investigate failure).

All these options can be set on the command line or via environment variables
(refer to the documentation for variable names).

<cmd> is one of:
  - config
  - init
  - start
  - stop
EOF
}

#=========================================================================
# Main

#----
# Get cmd line opts

export CTOOLS_LOGLEVEL="${CTOOLS_LOGLEVEL:-0}"
export CTOOLS_ROLE="${CTOOLS_ROLE:-}"
export CTOOLS_CFGDIR="${CTOOLS_CFGDIR:-/etc/ctools}"
export CTOOLS_TMPDIR="${CTOOLS_TMPDIR:-/tmp/ctools}"
export CTOOLS_DRY_RUN="${CTOOLS_DRY_RUN:-}"
export CTOOLS_FAILURE_FREEZE="${CTOOLS_FAILURE_FREEZE:-}"
export CTOOLS_NO_INIT="${CTOOLS_NO_INIT:-}"
export CTOOLS_RANK_BASE="${CTOOLS_RANK_BASE:-}"
export CTOOLS_RANK_STEP="${CTOOLS_RANK_STEP:-10}"

while getopts vb:s:c:r:t:nifhV _opt;	do
	case $_opt in
		v) CTOOLS_LOGLEVEL="$((CTOOLS_LOGLEVEL + 1))" ;;
    b) CTOOLS_RANK_BASE="$OPTARG" ;;
    s) CTOOLS_RANK_STEP="$OPTARG" ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    t) CTOOLS_TMPDIR="$OPTARG" ;;
    n) CTOOLS_DRY_RUN=y ;;
    i) CTOOLS_NO_INIT=y ;;
    f) CTOOLS_FAILURE_FREEZE=y ;;
		h) _ctools_run_usage ; exit 0 ;;
    V) echo "@VERSION@"; exit 0 ;;
		*) _ctools_run_usage ; exit 1 ;;
	esac
done

[ -d "$CTOOLS_TMPDIR" ] || mkdir -p "$CTOOLS_TMPDIR"

CTOOLS_INIT_ENVFILE="$CTOOLS_TMPDIR/envfile.sh"
_ctools_msg_debug "Init environment file: $CTOOLS_INIT_ENVFILE"

CTOOLS_IS_FROZEN="$CTOOLS_TMPDIR/frozen"
CTOOLS_IS_STOPPING="$CTOOLS_TMPDIR/stopping"

trap '_ctools_failure_handler $?' ERR

#----

shift $((OPTIND-1))
if [ $# = 0 ]; then
  _ctools_run_usage
  exit 1
fi
cmd="$1"
shift
"_ctools_$cmd" "$@"
