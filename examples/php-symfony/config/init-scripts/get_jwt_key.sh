# This script get the JWT public key from keycloak and records it.
#
# Requires the following software to be installed :
#   - curl
#
# Requires the following environment variables:
#   - KEYCLOAK_URL - Optional - if not set, do nothing
#   - KEYCLOAK_REALM
#   - RETRY_INTERVAL (optional, default=30)
#   - INSECURE (optional, default='') - allow insecure certificate for keycloak
#=============================================================================

if [ -n "${KEYCLOAK_URL:-}" ]; then
  JWT_URL="${KEYCLOAK_URL:-}/auth/realms/${KEYCLOAK_REALM:-}"

  RETRY_INTERVAL="${RETRY_INTERVAL:-30}"
  INSECURE="${INSECURE:-}"
  [ "X$INSECURE" != X ] && CURL="$CURL -k" || :

  #----

  while true; do
    echo "-- Getting JWT JSON struct"
    st=
    $CURL "$JWT_URL" -o jwt.json || st=1
    if [ -f jwt.json ]; then
      if grep error jwt.json >/dev/null; then
        echo "***ERROR: Got this from keycloak:"
        cat jwt.json
        st=1
      fi
    if [ -n "$st" ]
      echo "Curl failed - retrying..." \
      sleep $RETRY_INTERVAL \
      continue
    fi

    key="`sed -e 's/^.*,.public_key.:.//' -e 's/.,.*$//g' <jwt.json`"
    JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
$key
-----END PUBLIC KEY-----"
    ctools_save_var JWT_PUBLIC_KEY

    #----
    break
  done
else
  echo "-- KEYCLOAK_URL not set - ignoring this step"
fi
