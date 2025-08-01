# This script checks DB accessibility.
# Loop as long DB connection fails
# As the connection checks the AWS RDS CA certs, the 'db_ca_certs' init script
# must run before this one.
#
# It requires the following software to be installed :
#   - psql
# It requires the following environment variables:
#   - DB_URL
#=============================================================================

# Build connection string (url-encode path of CA cert file)

p="`echo $DB_CA_CERT_PATH | sed 's,/,%2F,g'`"
args="?sslmode=verify-full&ssl_min_protocol_version=TLSv1.2&sslrootcert=$p"
cstring="$DB_URL$args"

#----

while true ; do
  sf_msg_section "Checking access to the database"
  sf_debug "Connection string: $cstring"
  fi

  st=
  echo | "$PSQL" "$cstring" || st=1

  if [ -n "$st" ] ; then
    sf_error "Connection failed - Retrying..."
    sleep 10
    continue
  else
    sf_msg "OK"
    break
  fi
done
