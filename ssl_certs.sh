#!/usr/bin/env bash
#
# Based on https://github.com/joemiller/joemiller.me-intro-to-sensu/blob/master/ssl_certs.sh

function clean {
  find . -not -name "openssl.cnf" -not -name "ssl_certs.sh" -not -name "." -exec rm -Rf ./{} 2> /dev/null \;
}

function generate {
  mkdir -p tsacha_ca/private
  mkdir -p tsacha_ca/certs
  touch tsacha_ca/index.txt
  echo 01 > tsacha_ca/serial
  cd tsacha_ca
  openssl req -x509 -config ../openssl.cnf -newkey rsa:2048 -days 40000 -out cacert.pem -outform PEM -subj /CN=Tsacha_Ca/ -nodes
  cd ..
  openssl genrsa -out rabbitmq_key.pem 2048
  openssl req -new -key rabbitmq_key.pem -out rabbitmq_req.pem -outform PEM -subj /CN=$(hostname)/O=rabbitmq/ -nodes
  cd tsacha_ca
  openssl ca -config ../openssl.cnf -in ../rabbitmq_req.pem -out ../rabbitmq_cert.pem -notext -batch -extensions server_ca_extensions
  cd ..
  openssl genrsa -out sensu_key.pem 2048
  openssl req -new -key sensu_key.pem -out sensu_req.pem -outform PEM -subj /CN=$(hostname)/O=sensu/ -nodes
  cd tsacha_ca
  openssl ca -config ../openssl.cnf -in ../sensu_req.pem -out ../sensu_cert.pem -notext -batch -extensions client_ca_extensions
}

if [ "$1" = "generate" ]; then
  echo "Generating ssl certificates..."
  generate
  exit
elif [ "$1" = "clean" ]; then
  echo "Cleaning up previously generated certificates..."
  clean
else
  echo "You must run the script with either generate or clean, e.g. ./ssl_certs.sh generate"
fi
