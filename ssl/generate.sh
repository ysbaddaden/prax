#! /usr/bin/env sh

keygen() {
  openssl genrsa -out server.key 2048
}
csrgen() {
  openssl req -new -key server.key -out server.csr -subj "/C=/ST=/L=/O=Prax Dev Cert/OU=/CN=localhost"
}
crtgen() {
  openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
}

case "$1" in
  keygen)
    keygen
    ;;
  csrgen)
    csrgen
    ;;
  crtgen)
    crtgen
    ;;
  *)
    keygen
    csrgen
    crtgen
    ;;
esac
