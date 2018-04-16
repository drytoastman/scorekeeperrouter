
TAG := $(shell git describe --tags --abbrev=0)
TARGET := scorekeeper_${TAG}_all.ipk

${TARGET}: control/* etc/init.d/* ../*.lua
	cp ../*.lua scorekeeper/
	tar -czf control.tar.gz -C control control postinst prerm
	tar -czf data.tar.gz etc scorekeeper
	tar -czf $@ control.tar.gz data.tar.gz debian-binary

clean:
	rm -f *.gz
	rm -f ${TARGET}

