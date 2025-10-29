#!/bin/bash
#
# Run a Symfony messenger:consume loop
#
#----------------------------------------------------------------------------

set -euo pipefail

#--- Options

OPTS="--no-ansi -n -vvv"

[ -n "${ASYNC_JOB_LIMIT:-}" ] && OPTS="$OPTS --limit=$ASYNC_JOB_LIMIT"
[ -n "${ASYNC_TIME_LIMIT:-}" ] && OPTS="$OPTS --time-limit=$ASYNC_TIME_LIMIT"

ERROR_DELAY="${ASYNC_ERROR_DELAY:-10}"

if [ -z "${ASYNC_TRANSPORTS:-}" ]; then
  echo "***ERROR: The 'ASYNC_TRANSPORTS' environment variable must contain a list of transports to receive from"
  exit 1
fi

#--- Loop

while true ; do
  echo "---`date` - Starting messenger:consume"
  rc=0
  php bin/console messenger:consume $ASYNC_TRANSPORTS $OPTS || rc=$?
  if ctools is_stopping; then
    echo "--- Stop was requested - Going down..."
    break
  fi
  if [ $rc != 0 -a $rc != 137 ]; then
    echo "--- Received RC=$rc - sleeping $ASYNC_ERROR_DELAY seconds"
    sleep $ERROR_DELAY
  fi
done
