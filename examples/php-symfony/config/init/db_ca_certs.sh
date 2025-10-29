#-- This script is executed as initContainer by the API pod.
#-- It downloads and stores AWS RDS CA certificates, so that we can verify
#-- certificates received when connecting to an RDS instance
#-- This is used on Kubernetes environments only.
#
# It requires the following software to be installed :
#   - curl
# It also uses the following environment variables:
#   - DB_CA_CERT_URL - Optional. If not set, step is ignored
#   - DB_CA_CERT_PATH
#=============================================================================

if [ -n "${DB_CA_CERT_URL:-}" ] ; then
  while true; do
    echo "-- Getting DB CA certificates"
    echo "URL: $DB_CA_CERT_URL"
    echo "Target file: $DB_CA_CERT_PATH"
    echo

    _rc=0
    curl $DB_CA_CERT_URL -o "$DB_CA_CERT_PATH" || _rc=1

    if [ $_rc != 0 ] ; then
      echo "** Error - Cannot get DB CA certificates - Retrying..."
      sleep 10
      continue
    else
      echo "-- OK"
      break
    fi
  done
else
  echo "No URL defined - Ignoring step"
fi

#----------
