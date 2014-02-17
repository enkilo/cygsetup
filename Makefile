PACKAGE = cygsetup
VERSION = 1.2

prefix = /usr
bindir = ${prefix}/bin
datadir = ${prefix}/share

INSTALL = install -c

all:


install:
	$(INSTALL) -d  $(DESTDIR)$(bindir)
	$(INSTALL) -m 755 cygsetup.sh $(DESTDIR)$(bindir)/cygsetup
	$(INSTALL) -d  $(DESTDIR)$(datadir)/doc
	$(INSTALL) -m 755 README $(DESTDIR)$(datadir)/doc/$(PACKAGE)-$(VERSION).README