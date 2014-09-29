
DESTDIR ?= /

all:

install: install-net install-udev install-x11

install-net:
	install -d $(DESTDIR)/etc/network
	install -m 0644 conf/network/defaults-* $(DESTDIR)/etc/network

install-udev:
	install -d $(DESTDIR)/etc/udev/rules.d
	install -m 0644 conf/udev/rules.d/*.rules $(DESTDIR)/etc/udev/rules.d/

install-x11:
	install -d $(DESTDIR)/etc/X11/Xsession.d
	install -m 0755 conf/X11/Xsession.d/* $(DESTDIR)/etc/X11/Xsession.d/
