# This script starts a PHP cron job
#
# It uses 3 environment variables :
#   CRON_JOB: Job name
#   CRON_SYMFONY_CMD: Symfony command to launch
#   CRON_CMD_OPTS: Optional. Arguments to add on the command line
#---------------------------------------------------------------------

set -eu
exec 2>&1

#------------

env | grep "^CRON_"

#------------

dir="$DOCKER_PHP_INI_DIR/cron/$CRON_JOB/conf.d"
if [ -d $dir ] ; then
  export PHP_INI_SCAN_DIR=$dir
  echo "<info> Using specific PHP scan dir: $PHP_INI_SCAN_DIR"

  echo "<info> Scan dir contents:"
  ls -l $PHP_INI_SCAN_DIR
else
  echo "<info> Using default PHP scan dir ($PHP_CONF_DIR)</info>"
fi

command_line="bin/console $CRON_SYMFONY_CMD ${CRON_CMD_OPTS:-}"
echo "<info> Executing command: $command_line"

exec php $command_line
