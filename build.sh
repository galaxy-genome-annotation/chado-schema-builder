#!/bin/bash
wget --quiet "https://github.com/GMOD/Chado/archive/${VERSION}.tar.gz"

tar xfz "${VERSION}.tar.gz"
cd "Chado-${VERSION}/chado/" || exit;

mv /opt/load.conf.tt2 /build/Chado-master/chado/load/tt2/load.conf.tt2

yes | perl Makefile.PL GMOD_ROOT="$GMOD_ROOT" DEFAULTS=1 RECONFIGURE=1
make
make install
make load_schema
make prepdb
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/${PKG}-${VERSION}-no-onto.sql"
echo "1,2,3,4,5,6" | make ontologies
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/${PKG}-${VERSION}.sql"
psql -h localhost -p 5432 -U postgres -c 'ALTER SCHEMA public RENAME TO chado'
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/${PKG}-${VERSION}-tripal.sql"

gzip < "/host/${PKG}-${VERSION}-no-onto.sql" > "/host/${PKG}-${VERSION}-no-onto.sql.gz"
gzip < "/host/${PKG}-${VERSION}.sql"         > "/host/${PKG}-${VERSION}.sql.gz"
gzip < "/host/${PKG}-${VERSION}-tripal.sql"  > "/host/${PKG}-${VERSION}-tripal.sql.gz"
