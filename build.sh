#!/bin/bash
wget --quiet "https://github.com/GMOD/Chado/archive/${BRANCH}.tar.gz"
tar xfz "${BRANCH}.tar.gz"
cd "Chado-${BRANCH}/chado/" || exit;

mv /opt/load.conf.tt2 /build/Chado-${VERSION}/chado/load/tt2/load.conf.tt2

VERSION=$(cat Makefile.PL | grep 'my $VERSION' | sed 's/.* = //g;s/;//';)

yes | perl Makefile.PL GMOD_ROOT="$GMOD_ROOT" DEFAULTS=1 RECONFIGURE=1
make
make install
make load_schema
make prepdb
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}-no-onto.sql"
echo "1,2,3,4,5,6" | make ontologies
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}.sql"
psql -h localhost -p 5432 -U postgres -c 'ALTER SCHEMA public RENAME TO chado'
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}-tripal.sql"

gzip < "/host/chado-${VERSION}-no-onto.sql" > "/host/chado-${VERSION}-no-onto.sql.gz"
gzip < "/host/chado-${VERSION}.sql"         > "/host/chado-${VERSION}.sql.gz"
gzip < "/host/chado-${VERSION}-tripal.sql"  > "/host/chado-${VERSION}-tripal.sql.gz"
