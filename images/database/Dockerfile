FROM postgres:alpine

RUN apk add --update --virtual .build-deps \
      gcc musl-dev linux-headers libxml2-dev python3-dev \
    && apk add --update py3-psycopg2 py3-pip

RUN wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	  python3 get-pip.py; \
    rm -f get-pip.py; \
    pip install --no-cache-dir -U subunit2sql; \
    apk del .build-deps

RUN mkdir -p /docker-entrypoint-initdb.d

# The init scripts are executed when the DB is listening to the socket only
# Using a readiness probe that connects to the IP address will ensure that
# the DB is not marked as ready and not accessible from outside until the
# DB migration is complete
COPY run_db_migrations.sh /docker-entrypoint-initdb.d/run_db_migrations.sh
