#!/bin/bash
#
#===========================================================================

set -euo pipefail

if [ -z "${SHELL:-}" ]; then
  echo "ERROR: the SHELL environment variable was not found"
  exit 1
fi

export DEB_BUILD_DIR="${DEB_BUILD_DIR:-`dirname $0`}"
export BUILD_DIR="`dirname $DEB_BUILD_DIR`"
export BASE_DIR="`dirname $BUILD_DIR`"
export BUILD_BASE="${BUILD_BASE:-/tmp/build/debian}"

NAME="container-tools"
VERSION="`cat $BASE_DIR/VERSION`"
NV="$NAME-$VERSION"
export TARGET="$BUILD_BASE/$NV"
DEB_TARGET="$TARGET/DEBIAN"

source "$BUILD_DIR/functions.sh"

#-------------

rm -rf $TARGET
mkdir -p "$DEB_TARGET"

ppc <$DEB_BUILD_DIR/control >$DEB_TARGET/control

$SHELL $BUILD_DIR/install.sh

dpkg -b "$TARGET"

mv -f "$TARGET.deb" "$BASE_DIR"
echo "Package file: $NV.deb"

rm -rf $TARGET
