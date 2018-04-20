
TRAVIS_TAG ?= $(shell git describe --tags --abbrev=0)
TARGET := scorekeeper_${TRAVIS_TAG}_all.deb
FILES  := $(shell find scorekeeper -type f)

${TARGET}: ${FILES} ../src/*.lua
	sed -i 's/Version: .*/Version: ${TRAVIS_TAG}/' scorekeeper/DEBIAN/control
	mkdir -p scorekeeper/scorekeeper
	cp ../src/*.lua scorekeeper/scorekeeper/
	dpkg-deb --build scorekeeper $@

clean:
	rm -f scorekeeper/scorekeeper/*.lua
	rm -f *.deb

