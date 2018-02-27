#!/bin/bash
set -ex
cd /build/

function fix_typedefs () {
    python /opt/obo_extract_typedefs.py /build/${1}.obo /build/${1}_typedefs.obo
    go2fmt.pl -p obo_text -w xml /build/${1}_typedefs.obo | go-apply-xslt oboxml_to_chadoxml - > /build/${1}_typedefs.xml
    stag-storenode.pl -d 'dbi:Pg:dbname=postgres;host=localhost;port=5432' --user postgres --password postgres /build/${1}_typedefs.xml
}

wget --quiet "https://github.com/GMOD/Chado/archive/${BRANCH}.tar.gz"

# Download ontologies
wget --quiet "https://raw.githubusercontent.com/The-Sequence-Ontology/SO-Ontologies/master/so.obo"
wget --quiet "http://geneontology.org/ontology/go.obo"
wget --quiet "https://raw.githubusercontent.com/Planteome/plant-ontology/master/po.obo"
wget --quiet "https://raw.githubusercontent.com/phenoscape/taxrank/master/taxrank.obo"

tar xfz "${BRANCH}.tar.gz"
cd "Chado-${BRANCH}/chado/" || exit;

patch -p1 < /opt/fix_relationshiptype_lc.diff

mv /opt/load.conf.tt2 /build/Chado-${BRANCH}/chado/load/tt2/load.conf.tt2
# Remove old versions in case bad things happen

yes | perl Makefile.PL GMOD_ROOT="$GMOD_ROOT" DEFAULTS=1 RECONFIGURE=1
make
make install
make load_schema
make prepdb
pg_dump --no-owner --no-acl postgres | gzip > "/build/chado-${BRANCH}-no-onto.sql.gz"
echo "1" | make ontologies
psql -c "UPDATE cvterm SET cv_id = 7 WHERE cv_id IN (SELECT cv_id FROM cv WHERE name='ro')"

gmod_load_cvterms.pl -s SO /build/so.obo
gmod_load_cvterms.pl -s GO /build/go.obo
gmod_load_cvterms.pl -s SOFP load/etc/feature_property.obo
gmod_load_cvterms.pl -s PO /build/po.obo
gmod_load_cvterms.pl -s TAXRANK /build/taxrank.obo

# Typedefs defined in each obo are loaded by gmod_load_cvterms.pl only if they are used
# Following lines add the typedefs that were not added
ln -s "/build/Chado-${BRANCH}/chado/load/etc/feature_property.obo" /build/feature_property.obo
fix_typedefs so
fix_typedefs go
fix_typedefs feature_property
fix_typedefs po
fix_typedefs taxrank

# Populate cvtermpath table
psql -h localhost -p 5432 -U postgres < /opt/cvtermpath_fix.sql
echo "select * from fill_cvtermpath('sequence');" | psql
echo "select * from fill_cvtermpath('plant_anatomy');" | psql
echo "select * from fill_cvtermpath('plant_structure_development_stage');" | psql
echo "select * from fill_cvtermpath('taxonomic_rank');" | psql
echo "select * from fill_cvtermpath('biological_process');" | psql
echo "select * from fill_cvtermpath('molecular_function');" | psql
echo "select * from fill_cvtermpath('cellular_component');" | psql

# Update links to external dbs
psql -h localhost -p 5432 -U postgres < /opt/update_urls.sql

pg_dump --no-owner --no-acl postgres | gzip > "/build/chado-${BRANCH}.sql.gz"
psql -c 'ALTER SCHEMA public RENAME TO chado'
pg_dump --no-owner --no-acl postgres | gzip > "/build/chado-${BRANCH}-tripal.sql.gz"

echo "The schema build has completed. The container will now intentionally crash"
exit 42;
