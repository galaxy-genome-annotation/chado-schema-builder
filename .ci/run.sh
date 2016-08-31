#!/bin/bash
# Set output directory if not set. This is parameterised as a variable as
# running this job inside a jenkins container may require complex volume
# setting if doing docker-next-to-docker.
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-$(pwd)/output}";
# Then we build the image if any changes have been made
make;
# And we run the tool
docker run --rm --volume="${OUTPUT_DIRECTORY}":/host \
	-e BRANCH=1.31 \
	-e DBSTAG_TRACE=1 \
	erasche/chado_schema_builder;
# This will likely fail! But that's OK.
retcode=$?
# Because if it exits with code 42 then we built the image successfully (or hit some very strange error ;))
if [ $retcode -eq 42 ]; then
	exit 0;
fi
# Otherwise we exit with the job's exit code.
exit $retcode;
#/opt/jenkins/data/jobs/Chado-Prebuilt-Schemas/workspace/compile-chado-schema/output
