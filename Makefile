build_container: build.sh Dockerfile
	docker build -t erasche/chado_schema_builder .

schema: build_container
	docker run -it --rm --volume=$(shell pwd)/output:/host -e VERSION=master erasche/chado_schema_builder

.PHONY: schema build_container
