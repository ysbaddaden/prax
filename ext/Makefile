CC=gcc
CFLAGS=-O2

OBJ=nss_prax.o

%.o: %.c
	$(CC) -Wall -fPIC -c -o $@ $< $(CFLAGS)

libnss_prax.so.2: $(OBJ)
	$(CC) -shared -o $@ $^ -Wl,-soname,libnss_prax.so.2 $(CFLAGS)

clean:
	rm -f *.o *~ libnss_prax.so.2

install:
	ln -sf $(CURDIR)/libnss_prax.so.2 /lib

uninstall:
	rm /lib/libnss_prax.so.2

