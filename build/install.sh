#!/bin/bash
#
# This script is supposed to be run from the repo base directory as :
#     bash build/install.sh
# Optional env variables :
#     - BINDIR: Directory where executable scripts will be installed. Dir
#               must be in $PATH when commands are run. Default: /usr/bin
#===========================================================================

set -euo pipefail

if [ -z "${SHELL:-}" ]; then
  echo "ERROR: the SHELL environment variable was not found"
  exit 1
fi

BUILD_DIR="`dirname $0`"
BASE_DIR="`dirname $BUILD_DIR`"

BINDIR="${BINDIR:-/usr/bin}"
CFGDIR="${CFGDIR:-/etc/ctools}"

#--- Copy scripts to bin dir and make them executable

cd $BASE_DIR/bin
for i in *.sh; do
  target="$BINDIR/`basename $i .sh`"
  echo "Installing $target..."
  echo "#!$SHELL" >$target
  cat $i >>$target
  chmod +x $target
done

#--- Create empty config dir if it does not exist already

if [ ! -d "$CFGDIR" ]; then
  echo "$CFGDIR: creating directory"
  mkdir -p "$CFGDIR"
fi
