VERSION=$(shell git describe --always | sed 's|v\(.*\)|\1|')
BRANCH=$(shell git rev-parse --abbrev-ref HEAD | sed 's|/|-|g')
OS:=$(shell uname -s | awk '{ print tolower($$1) }')
ARCH=amd64
ORGANIZATION=timescale
TARGET=wal-e

.PHONY: clean docker-image docker-push prepare-for-docker-build

docker-image: Dockerfile src/wale-rest.py run.sh
	docker build -t $(ORGANIZATION)/$(TARGET):latest .
	docker tag $(ORGANIZATION)/$(TARGET):latest $(ORGANIZATION)/$(TARGET):${VERSION}
	docker tag $(ORGANIZATION)/$(TARGET):latest $(ORGANIZATION)/$(TARGET):${BRANCH}

docker-push: docker-image
	docker push $(ORGANIZATION)/$(TARGET):latest
	docker push $(ORGANIZATION)/$(TARGET):${VERSION}

clean:
	rm -f *~ src/*~
