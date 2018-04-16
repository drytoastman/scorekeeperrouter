
TAG := $(shell git describe --tags --abbrev=0)
TARGET := scorekeeper_${TAG}_all.ipk

${TARGET}: control/* etc/init.d/* ../*.lua
	cp ../*.lua scorekeeper/
	tar --owner=0 --group=0 -czf control.tar.gz -C control control postinst prerm
	tar --owner=0 --group=0 -czf data.tar.gz etc scorekeeper
	tar --owner=0 --group=0 -czf $@ control.tar.gz data.tar.gz debian-binary

clean:
	rm -f *.gz
	rm -f *.ipk

