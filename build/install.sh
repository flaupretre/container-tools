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

TARGET="${TARGET:-}"
BUILD_DIR="${BUILD_DIR:-`dirname $0`}"
BASE_DIR="${BASE_DIR:-`dirname $BUILD_DIR`}"
VERSION="`cat $BASE_DIR/VERSION`"

BINDIR="$TARGET/usr/bin"
CFGDIR="$TARGET/etc/ctools"

source "$BUILD_DIR/functions.sh"

#---

for dir in $BINDIR $CFGDIR; do
  if [ ! -d "$dir" ]; then
    echo "$dir: creating directory"
    mkdir -p "$dir"
  fi
done

#--- Copy scripts to bin dir and make them executable

for i in $BASE_DIR/bin/*.sh; do
  base="`basename $i .sh`"
  target="$BINDIR/$base"
  echo "Installing $base..."
  echo "#!$SHELL" >"$target"
  ppc <"$i" >>"$target"
  chmod 0755 $target
done

#---

chown -Rh root:root "$TARGET"
