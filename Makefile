
.PHONY: build run
build: Dockerfile
	./bin/build.sh

run: build
	./bin/run.sh

