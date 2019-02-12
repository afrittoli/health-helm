#!/bin/sh
set -x

# Connect on socket to the local DB
DB_URI="postgresql+psycopg2:///$DB_NAME?user=$POSTGRES_USER"
/usr/bin/subunit2sql-db-manage --database-connection $DB_URI upgrade head
