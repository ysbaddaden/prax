#! /usr/bin/env sh

SUDO=`touch "test" 2>/dev/null && rm "test" || echo "sudo"`

if [ ! -e server.key ]; then
  $SUDO openssl genrsa -out server.key 2048
fi

if [ ! -e server.csr ]; then
  $SUDO openssl req -new -key server.key -out server.csr \
    -subj "/C=/ST=/L=/O=Prax Dev Cert/OU=/CN=localhost"
fi

if [ ! -e server.crt ]; then
  $SUDO openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
fi
