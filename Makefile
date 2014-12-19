CONFIG ?= mainos
DESTDIR ?= /
SRCDIRS = files/common files/$(CONFIG)

all:
.PHONY: all

install:
	@for dir in $(SRCDIRS); do \
		rsync -av $$dir/ $(DESTDIR)/ ; \
	done
.PHONY: install
