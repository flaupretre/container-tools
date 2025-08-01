
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
  sf_trace "Sourcing file: $file"
  if [ -f "$file" ]; then
    source "$file"
  else
    if [ -n "$ignore" ]; then
      sf_trace "File '$file' not found - ignoring"
    else
      sf_error "File '$file' not found"
      return 1
  fi
done
}

#----

sf_verbose_level="${CTOOLS_LOGLEVEL:-0}"
CTOOLS_ERRORS=0
CTOOLS_PHASE="${CTOOLS_PHASE:-init}"
CTOOLS_ROLE="${CTOOLS_ROLE:-}"
CTOOLS_CFGDIR="${CTOOLS_CFGDIR:-/etc/ctools}"
CTOOLS_TMPDIR="${CTOOLS_TMPDIR:-/tmp}"
CTOOLS_ENVFILE="$CTOOLS_TMPDIR/ctools-init-env.sh"

#----

. sysfunc
