#!/bin/bash
set -ex
wget --quiet "https://github.com/GMOD/Chado/archive/${BRANCH}.tar.gz"

# Download ontologies
wget --quiet "http://song.cvs.sourceforge.net/*checkout*/song/ontology/so.obo"
wget --quiet "http://geneontology.org/ontology/go.obo"
wget --quiet "https://raw.githubusercontent.com/Planteome/plant-ontology/master/po.obo"
wget --quiet "https://raw.githubusercontent.com/phenoscape/taxrank/master/taxrank.obo"

tar xfz "${BRANCH}.tar.gz"
cd "Chado-${BRANCH}/chado/" || exit;

mv /opt/load.conf.tt2 /build/Chado-${BRANCH}/chado/load/tt2/load.conf.tt2

VERSION=$(cat Makefile.PL | grep 'my $VERSION' | sed 's/.* = //g;s/;//';)

yes | perl Makefile.PL GMOD_ROOT="$GMOD_ROOT" DEFAULTS=1 RECONFIGURE=1
make
make install
make load_schema
make prepdb
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}-no-onto.sql"
echo "1" | make ontologies
psql -h localhost -p 5432 -U postgres -c "UPDATE cvterm SET cv_id = 7 WHERE cv_id IN (SELECT cv_id FROM cv WHERE name='ro')"

gmod_load_cvterms.pl -s SO /build/so.obo
gmod_load_cvterms.pl -s GO /build/go.obo
gmod_load_cvterms.pl -s SOFP load/etc/feature_property.obo
gmod_load_cvterms.pl -s PO /build/po.obo
gmod_load_cvterms.pl -s TAXRANK /build/taxrank.obo

# Populate cvtermpath table
psql -h localhost -p 5432 -U postgres < /opt/cvtermpath_fix.sql
echo "select * from fill_cvtermpath('sequence');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('plant_anatomy');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('plant_structure_development_stage');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('taxonomic_rank');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('biological_process');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('molecular_function');" | psql -h localhost -p 5432 -U postgres
echo "select * from fill_cvtermpath('cellular_component');" | psql -h localhost -p 5432 -U postgres

pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}.sql"
psql -h localhost -p 5432 -U postgres -c 'ALTER SCHEMA public RENAME TO chado'
pg_dump -h localhost -p 5432 -U postgres --no-owner --no-acl postgres > "/host/chado-${VERSION}-tripal.sql"

gzip < "/host/chado-${VERSION}-no-onto.sql" > "/host/chado-${VERSION}-no-onto.sql.gz"
gzip < "/host/chado-${VERSION}.sql"         > "/host/chado-${VERSION}.sql.gz"
gzip < "/host/chado-${VERSION}-tripal.sql"  > "/host/chado-${VERSION}-tripal.sql.gz"

echo "The schema build has completed. The container will now intentionally crash"
exit 42;
