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
# This script is run after cmd line opts are parsed, so that variables have
# their final values
#=============================================================================

[ -d $CTOOLS_TMPDIR ] || mkdir -p $CTOOLS_TMPDIR

if [ ! -d "$CTOOLS_CFGDIR" ]; then
  _ctools_msg_error "$CTOOLS_CFGDIR: Config dir not found"
  exit 1
fi

CTOOLS_INIT_ENVFILE="$CTOOLS_TMPDIR/envfile.sh"
_ctools_msg_debug "Init environment file: $CTOOLS_INIT_ENVFILE"

CTOOLS_FROZEN="$CTOOLS_TMPDIR/frozen"

trap '_ctools_failure_handler $?' ERR
