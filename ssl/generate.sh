#! /usr/bin/env sh

if [ ! -e server.key ]; then
  openssl genrsa -out server.key 2048
fi

if [ ! -e server.csr ]; then
  openssl req -new -key server.key -out server.csr \
    -subj "/C=/ST=/L=/O=Prax Dev Cert/OU=/CN=localhost"
fi

if [ ! -e server.crt ]; then
  openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
fi
