
all:
	make -C openwrt
	make -C debian

clean:
	make -C openwrt clean
	make -C debian clean

