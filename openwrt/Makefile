
TAG := $(shell git describe --tags --abbrev=0)
TARGET := scorekeeper_${TAG}_all.ipk

${TARGET}: control/* data/etc/init.d/* ../src/*.lua
	mkdir -p data/scorekeeper
	cp ../src/*.lua data/scorekeeper/
	tar --owner=0 --group=0 -czf control.tar.gz -C control control postinst prerm postrm
	tar --owner=0 --group=0 -czf data.tar.gz    -C data    etc scorekeeper
	tar --owner=0 --group=0 -czf $@ control.tar.gz data.tar.gz -C control debian-binary

clean:
	rm -f data/scorekeeper/*.lua
	rm -f *.gz
	rm -f *.ipk

