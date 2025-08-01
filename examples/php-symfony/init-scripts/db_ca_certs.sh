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
    sf_msg "-- Getting DB CA certificates"
    sf_trace "URL: $DB_CA_CERT_URL"
    sf_debug "Target file: $DB_CA_CERT_PATH"
    sf_msg

    _rc=0
    $CURL $DB_CA_CERT_URL -o "$DB_CA_CERT_PATHh" || _rc=1

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
