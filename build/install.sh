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
# This script is supposed to be run from the repo base directory as :
#     bash build/install.sh
#===========================================================================

set -euo pipefail

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

for i in $BASE_DIR/src/*.sh; do
  base="`basename $i .sh`"
  target="$BINDIR/$base"
  echo "Installing $base..."
  echo "#!/usr/bin/env bash" >"$target"
  ppc <"$i" >>"$target"
  chmod 0755 $target
done

#---
