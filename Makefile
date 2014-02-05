PREFIX=build
PRAXDIR=$(PREFIX)/opt/prax
BINDIR=$(PREFIX)/usr/bin
LIBDIR=$(PREFIX)/lib
INITD=$(PREFIX)/etc/init.d
DOCDIR=$(PREFIX)/opt/prax/doc
#GNOME_AUTOSTART=$(PREFIX)/usr/share/gnome/autostart
VERSION=`cat ../VERSION`

all:
	cd ext && make

install: all
	mkdir -p $(LIBDIR) $(INITD) $(PRAXDIR) $(BINDIR) $(DOCDIR)
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
	cd build && fpm -s dir -t $(TARGET) -n "prax" -v $(VERSION) -d 'ruby-interpreter' \
		--maintainer julien@portalier.com --url http://ysbaddaden/github.io/prax\
		--description "Rack Proxy Server" --vendor "" \
		--license "MIT License" --category devel \
		--after-install ../install/postinst --before-remove ../install/prerm \
		etc lib opt usr

deb:
	TARGET=deb make package

rpm:
	TARGET=rpm make package

clean:
	rm -rf build

