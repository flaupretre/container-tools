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
# This script build a '.deb' package
#=============================================================================

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
