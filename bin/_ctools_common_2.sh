#
# This script is run after cmd line opts are parsed, so that variables have
# their final values
#============================================================================

[ -d $CTOOLS_TMPDIR ] || mkdir -p $CTOOLS_TMPDIR

if [ ! -d "$CTOOLS_CFGDIR" ]; then
  _ctools_msg_error "$CTOOLS_CFGDIR: Config dir not found"
  exit 1
fi

CTOOLS_INIT_ENVFILE="$CTOOLS_TMPDIR/envfile.sh"
_ctools_msg_debug "Init environment file: $CTOOLS_INIT_ENVFILE"

CTOOLS_FROZEN="$CTOOLS_TMPDIR/frozen"

trap '_ctools_failure_handler $?' ERR
