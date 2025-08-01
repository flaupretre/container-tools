#!/bin/bash
#
#===========================================================================

set -euo pipefail
exec 2>&1

#---------------------------------

function _ctools_init_usage
{
#TODO
}

#----

function _ctools_env_nl
{
echo >>"$CTOOLS_ENVFILE"
}

#----

function ctools_save_var
{
local var value

for var; do
  _ctools_env_nl
  value="${!var}"
  vstring="`echo $value | sed -e 's,\,\\,g' -e 's,",\",g'`"
  echo "export $var=\"$vstring\"" >>"$CTOOLS_ENVFILE"
done
}

#---------------------------------
# Main

. ctools-common

while getopts vc:r:d:h _opt;	do
	case $_opt in
		v) sf_verbose_level=`expr $sf_verbose_level + 1` ;;
    c) CTOOLS_CFGDIR="$OPTARG" ;;
    r) CTOOLS_ROLE="$OPTARG" ;;
    d) CTOOLS_TMPDIR="$OPTARG" ;;
		h) _ctools_init_usage ; exit 0 ;;
		?) _ctools_init_usage ; exit 1 ;;
	esac
done

[ -d $CTOOLS_TMPDIR ] || sf_create_dir $CTOOLS_TMPDIR
cd $CTOOLS_TMPDIR

sf_debug "Environment file: $CTOOLS_ENVFILE"
touch $CTOOLS_ENVFILE

#----

CTOOLS_INIT_SCRIPTS=""

_ctools_source_cfg_script -i "env"
[ -n "$CTOOLS_ROLE" ] && _ctools_source_cfg_script -i "role/$CTOOLS_ROLE/env"

for script in $CTOOLS_INIT_SCRIPTS; do
  sf_separator
  sf_section "Executing init script: $_script"
  _ctools_source_cfg_script "common/init/scripts/$_script"
done

#----

if [ "$CTOOLS_ERRORS" != 0 ] ; then
    sf_fatal "Errors detected ($CTOOLS_ERRORS) - Aborting" $CTOOLS_ERRORS
fi

#----

if [ "$sf_verbose_level" -ge 2 ]; then
  sf_banner "Resulting environment file"
  cat $CTOOLS_ENVFILE
  sf_separator
fi
