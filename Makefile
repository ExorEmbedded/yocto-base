
DESTDIR ?= /

all:
.PHONY: all

install: install-conf install-scripts install-initd
.PHONY: install

install-conf: install-formfactor install-net install-udev install-profile install-x11
.PHONY: install-conf

install-scripts:
	install -d $(DESTDIR)/usr/bin
	install -m 0755 scripts/* $(DESTDIR)/usr/bin
.PHONY: install-scripts

install-formfactor:
	install -d $(DESTDIR)/etc/formfactor
	install -m 0644 conf/formfactor/* $(DESTDIR)/etc/formfactor
.PHONY: install-formfactor

install-net:
	install -d $(DESTDIR)/etc/network
	install -m 0644 conf/network/defaults-* $(DESTDIR)/etc/network
.PHONY: install-net

install-udev:
	install -d $(DESTDIR)/etc/udev/
	rsync -av conf/udev/ $(DESTDIR)/etc/udev/
.PHONY: install-udev

install-profile:
	install -d $(DESTDIR)/etc/profile.d
	install -m 0755 conf/profile.d/* $(DESTDIR)/etc/profile.d
.PHONY: install-profile

install-x11:
	install -d $(DESTDIR)/etc/X11/Xsession.d
	install -m 0755 conf/X11/Xsession.d/* $(DESTDIR)/etc/X11/Xsession.d/
.PHONY: install-x11

install-initd:
	install -d $(DESTDIR)/etc/init.d/
	install -m 0755 conf/init.d/* $(DESTDIR)/etc/init.d
.PHONY: install-initd
