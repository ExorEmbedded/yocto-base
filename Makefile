
DESTDIR ?= /

all:
.PHONY: all

install: install-net install-udev install-x11
.PHONY: install

install-net:
	install -d $(DESTDIR)/etc/network
	install -m 0644 conf/network/defaults-* $(DESTDIR)/etc/network
.PHONY: install-net

install-udev:
	install -d $(DESTDIR)/etc/udev/rules.d
	install -m 0644 conf/udev/rules.d/*.rules $(DESTDIR)/etc/udev/rules.d/
.PHONY: install-udev

install-x11:
	install -d $(DESTDIR)/etc/X11/Xsession.d
	install -m 0755 conf/X11/Xsession.d/* $(DESTDIR)/etc/X11/Xsession.d/
.PHONY: install-x11
