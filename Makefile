DESTDIR ?= /
SRCDIRS = files/common 

ifeq ($(CONFIG), mainos)
    SRCDIRS += files/mainos
else
ifeq ($(CONFIG), configos)
    SRCDIRS += files/configos
else
    SRCDIRS = files
endif
endif

all:
.PHONY: all

install:
	@for dir in $(SRCDIRS); do \
		rsync -av $$dir/ $(DESTDIR)/ ; \
	done
.PHONY: install
