
FROM php:<version>-fpm

#TODO: Install ctools

ENV DB_CA_CERT_PATH=/tmp/db_ca_certs.pem

COPY . /build
RUN /build/config.sh

CMD ctools start
