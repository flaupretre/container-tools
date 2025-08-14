
BINDIR = /usr/bin

install:
	BINDIR=$(BINDIR) bash build/install.sh

deb:
	bash build/debian/mk_deb.sh

clean:
	rm -rf *.deb
