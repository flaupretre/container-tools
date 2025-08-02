#
# This script is run after cmd line opts are parsed, so that variables have
# their final values
#============================================================================

function _ctools_cfg_script_path
{
echo "$CTOOLS_CFGDIR/$1.sh"
}

#----

function _ctools_source_cfg_script
{
local arg file ignore

ignore=
if [ "X$1" = "X-i" ]; then
  ignore=y
  shift
fi

for arg; do
  file="`_ctools_cfg_script_path $arg`"
  _ctools_msg_trace "Sourcing file: $file"
  if [ -f "$file" ]; then
    source "$file"
  else
    if [ -n "$ignore" ]; then
      _ctools_msg_trace "File '$file' not found - ignoring"
    else
      _ctools_msg_error "File '$file' not found"
      return 1
    fi
  fi
done
}

#----

function _ctools_init_create_env
{
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

function ctools_init_save_var
{
local var value

for var; do
  echo >>"$CTOOLS_INIT_ENVFILE"
  value="${!var}"
  vstring="`echo $value | sed -e 's,\,\\,g' -e 's,",\",g'`"
  echo "export $var=\"$vstring\"" >>"$CTOOLS_INIT_ENVFILE"
done
}

#----
# Load environment variables saved by init scripts.
# If init has not run and $CTOOLS_ENSURE_INIT is set, run it.

function _ctools_load_init_env
{
if [ ! -f "$CTOOLS_INIT_ENVFILE" ]; then
  _ctools_msg_trace "Seems init was not run yet"
  if [ -n "$CTOOLS_ENSURE_INIT" ]; then
    echo "About to run init because it was not run yet"
    init_container
  fi
fi

if [ -f "$CTOOLS_INIT_ENVFILE" ]; then
  _ctools_msg_trace "Loading init environment from $CTOOLS_INIT_ENVFILE"
  source "$CTOOLS_INIT_ENVFILE"
else
  _ctools_msg_trace "Init env file ($CTOOLS_INIT_ENVFILE) not found"
fi

if [ "$CTOOLS_LOGLEVEL" -ge 2 ]; then
  echo "Environment after loading init env :"
  _ctools_msg_separator
  env
  _ctools_msg_separator
fi
}

#----

function _ctools_load_cfg_env
{
_ctools_source_cfg_script -i "env"

[ -n "$CTOOLS_ROLE" ] && _ctools_source_cfg_script -i "role/$CTOOLS_ROLE/env" || :
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

function _ctools_failure_handler
{
local rc line file

rc="$1"
set -- `caller 1`
_ctools_msg_error "$3: Script failure (line: $1, rc: $rc)"

if [ -n "$CTOOLS_FREEZE_ON_FAILURE" ]; then
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
export CTOOLS_FREEZE_ON_FAILURE="${CTOOLS_FREEZE_ON_FAILURE:-}"

[ -d $CTOOLS_TMPDIR ] || mkdir -p $CTOOLS_TMPDIR

if [ ! -d "$CTOOLS_CFGDIR" ]; then
  _ctools_msg_trace "$CTOOLS_CFGDIR: Config dir not found"
fi

CTOOLS_INIT_ENVFILE="$CTOOLS_TMPDIR/envfile.sh"
_ctools_msg_debug "Init environment file: $CTOOLS_INIT_ENVFILE"

CTOOLS_FROZEN="$CTOOLS_TMPDIR/frozen"

trap '_ctools_failure_handler $?' ERR
