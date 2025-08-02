
CURL=${CURL:-curl}
PSQL=${PSQL:-psql}

DB_CA_CERT_PATH="$CTOOLS_TMPDIR/db_ca_certs.pem"

COMMON_INIT=" \
    db_ca_certs     \
    pg_check_db     \
    db_migrations"

JWT_INIT="get_jwt_key"

CTOOLS_ENSURE_INIT=y

# Default list of init scripts to run

CTOOLS_INIT_SCRIPTS="$COMMON_INIT"