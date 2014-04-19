PREFIX=build
PRAXDIR=$(PREFIX)/opt/prax
BINDIR=$(PREFIX)/usr/bin
LIBDIR=$(PREFIX)/lib
INITD=$(PREFIX)/etc/init.d
DOCDIR=$(PREFIX)/opt/prax/doc
#GNOME_AUTOSTART=$(PREFIX)/usr/share/gnome/autostart
VERSION=`cat ../VERSION`

DEBIAN_DEPENDENCIES="-d 'ruby-interpreter (>= 1.9.3)' -d 'ruby-rack'"
FEDORA_DEPENDENCIES="-d 'ruby' -d 'rubygem-rack'"

all:
	cd ext && make

install: all
	mkdir -p $(LIBDIR) $(INITD) $(PRAXDIR) $(BINDIR) $(DOCDIR) #$(GNOME_AUTOSTART)
	cp -r bin libexec lib templates $(PRAXDIR)
	cp install/initd $(INITD)/prax
	cp ext/libnss_prax.so.2 $(LIBDIR)
	cd $(BINDIR) && ln -sf ../../opt/prax/bin/prax
	cp README.rdoc LICENSE install/prax.desktop $(DOCDIR)
	#cp install/prax.desktop $(GNOME_AUTOSTART)
	chmod -R 0755 $(PRAXDIR)/bin $(PRAXDIR)/libexec $(LIBDIR)/libnss_prax.so.2 $(INITD)/prax
	chmod -R 0755 `find $(PRAXDIR)/lib $(PRAXDIR)/templates $(PRAXDIR)/doc -type d`
	chmod -R 0644 `find $(PRAXDIR)/lib $(PRAXDIR)/templates $(PRAXDIR)/doc -type f`

package: install
	cd build && fpm -s dir -t $(TARGET) -n "prax" -v $(VERSION) $(DEPENDENCIES) \
		--maintainer julien@portalier.com --url http://ysbaddaden/github.io/prax\
		--description "Rack Proxy Server" --vendor "" \
		--license "MIT License" --category devel \
		--after-install ../install/postinst --before-remove ../install/prerm \
		etc lib opt usr

deb:
	TARGET=deb DEPENDENCIES=$(DEBIAN_DEPENDENCIES) make package

rpm:
	TARGET=rpm DEPENDENCIES=$(FEDORA_DEPENDENCIES) make package

clean:
	rm -rf build

