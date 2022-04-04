#!/bin/bash
set -x
# Set output directory if not set. This is parameterised as a variable as
# running this job inside a jenkins container may require complex volume
# setting if doing docker-next-to-docker.
VERSION=1.31
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-$(pwd)/output}";
# Then we build the image if any changes have been made
make;
# And we run the tool
docker run \
	-e BRANCH=$VERSION \
	-e DBSTAG_TRACE=1 \
	galaxy-genome-annotation/chado-schema-builder;
# This will likely fail! But that's OK.
retcode=$?
# Because if it exits with code 42 then we built the image successfully (or hit some very strange error ;))
if [ $retcode -eq 42 ]; then
	# Get the most recently run copy of this image. This *feels* incredibly
	# hacky but since we're checking exit code above it's hard to figure
	# another way to do this. We should probably move to launching it in the
	# background and then polling it continuously.
	CONTAINER_ID=$(docker ps -a  |grep galaxy-genome-annotation/chado-schema-builder | head -n 1 | cut -c1-12);
	# And copy the files out of it
	docker cp ${CONTAINER_ID}:/build/chado-${VERSION}-no-onto.sql.gz chado-${VERSION}-no-onto.sql.gz
	docker cp ${CONTAINER_ID}:/build/chado-${VERSION}.sql.gz chado-${VERSION}.sql.gz
	docker cp ${CONTAINER_ID}:/build/chado-${VERSION}-tripal.sql.gz chado-${VERSION}-tripal.sql.gz
	docker rm ${CONTAINER_ID}
	exit 0;
fi
# Otherwise we exit with the job's exit code.
exit $retcode;
#/opt/jenkins/data/jobs/Chado-Prebuilt-Schemas/workspace/compile-chado-schema/output
