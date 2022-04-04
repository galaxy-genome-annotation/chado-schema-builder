build_container: build.sh Dockerfile
	docker build -t hexylena/chado-schema-builder --file Dockerfile.inherit .

schema: build_container
	docker run -it --rm --volume=$(shell pwd)/output:/host -e BRANCH=1.31 hexylena/chado-schema-builder

.PHONY: schema build_container
