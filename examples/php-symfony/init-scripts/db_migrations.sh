#-- This script is executed as initContainer by the API pod.
#-- Not valid for local builds/runs.
#-- Executes not yet executed Symfony migration scripts
#=============================================================================

if [ -z "${LOCAL:-}" ]; then
  echo "--- Running Symfony migrations"

  cd $BASE_DIR
  bin/console doctrine:migrations:migrate --conn=default --no-interaction --allow-no-migration --no-ansi -v

else
  echo "Nothing to do on local runs"
fi
