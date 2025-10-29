#!/bin/bash
#
# Stop a Symfony messenger worker
#
#----------------------------------------------------------------------------

set -euo pipefail

ps -efww \
  | grep ' php bin/console messenger:consume $ASYNC_TRANSPORTS $OPTS' \
  | grep -v grep \
  | awk '{ print $2 }' \
  | xargs kill
