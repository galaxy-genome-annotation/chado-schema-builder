#!/bin/bash
mkdir -p output
mv chado*.gz output/

set -ex
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-$(pwd)/output}";
if [ ! -e ghr  ]; then
	wget "https://github.com/tcnksm/ghr/releases/download/v0.4.0/ghr_v0.4.0_linux_amd64.zip";
	unzip ghr_v0.4.0_linux_amd64.zip;
	chmod +x ghr
fi

CHADO_VERSION=$(find "output" | grep -o 'chado-[/0-9.]*.sql.gz' | sed 's/chado-//g;s/\.sql\.gz//g;')
./ghr -u erasche -r chado-schema-builder "${CHADO_VERSION}-jenkins${BUILD_ID}" output
