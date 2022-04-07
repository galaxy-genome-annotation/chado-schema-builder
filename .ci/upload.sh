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
CHADO_BUILD_ID=$(date "+%Y-%m-%d")
./ghr -u galaxy-genome-annotation -r chado-schema-builder "${CHADO_VERSION}-build${CHADO_BUILD_ID}" output
