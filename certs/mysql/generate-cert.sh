#!/bin/bash

# You have to put this shell script to linux system'system '/root/certs' directory
# and then use `chmod a+x generate-cert.sh`
# last use `./generate-cert.sh`

ROOT_DIR=/root/certs
CURRENT_DATETIME=`date +%Y-%m-%d_%H:%M:%S`
SAVE_DIR=$ROOT_DIR/$CURRENT_DATETIME/$HOST
PKCS12_EXPORT_PASSWORD=12123123
KEY_PASSWORD=Apple1234P@ssw0rd

MYSQL_CA_KEY_FILE=$SAVE_DIR/mysql-ca-key.pem
MYSQL_CA_CERT_FILE=$SAVE_DIR/mysql-ca-cert.pem
MYSQL_CA_P12_FILE=$SAVE_DIR/mysql-ca-cert.p12

MYSQL_SERVER_CNF_FILE=$SAVE_DIR/mysql.cnf
MYSQL_SERVER_CONFIG_FILE=$ROOT_DIR/mysql-server.cnf
MYSQL_SERVER_KEY_FILE=$SAVE_DIR/mysql-server-key.pem
MYSQL_SERVER_CSR_FILE=$SAVE_DIR/mysql-server-req.csr
MYSQL_SERVER_CERT_FILE=$SAVE_DIR/mysql-server-cert.pem
MYSQL_SERVER_P12_FILE=$SAVE_DIR/mysql-server-cert.p12

MYSQL_CLIENT_CNF_FILE=$SAVE_DIR/mysql-client.cnf
MYSQL_CLIENT_KEY_FILE=$SAVE_DIR/mysql-client-key.pem
MYSQL_CLIENT_CSR_FILE=$SAVE_DIR/mysql-client-req.csr
MYSQL_CLIENT_CERT_FILE=$SAVE_DIR/mysql-client-cert.pem
MYSQL_CLIENT_P12_FILE=$SAVE_DIR/mysql-client-cert.p12

HOST=mysql.homedev.net

# create directory
echo -e "\n>> create save directory"
mkdir -p $SAVE_DIR

echo -e "\n>>create ca certificate"
# generate ca key
openssl genrsa -out $MYSQL_CA_KEY_FILE 4096;
# generate ca certificate request
openssl req -subj "/C=CN/ST=Shanghai/L=SH/O=My\ Group/OU=Java\ Development\	Team/CN=MySQL CA" -new -x509 -nodes -days 365 -key $MYSQL_CA_KEY_FILE -out $MYSQL_CA_CERT_FILE;

echo -e "\n>> create server certificate"
# generate server cert request
openssl req -subj "/C=CN/ST=Shanghai/L=SH/O=My\ Group/OU=Java\ Development\ Team/CN=$HOST" -newkey rsa:4096 -days 365 -nodes -keyout $MYSQL_SERVER_KEY_FILE -out $MYSQL_SERVER_CSR_FILE;
openssl rsa -in $MYSQL_SERVER_KEY_FILE -out $MYSQL_SERVER_KEY_FILE;
# use ca cert to sign the server cert
openssl x509 -req -in $MYSQL_SERVER_CSR_FILE -days 365 -CA $MYSQL_CA_CERT_FILE -CAkey $MYSQL_CA_KEY_FILE -CAcreateserial -out $MYSQL_SERVER_CERT_FILE;

echo -e "\n>> create client certificate\n"
# generate client key and request
openssl req -subj "/C=CN/ST=Shanghai/L=SH/O=My\ Group/OU=Java\ Development\ Team/CN=mysql-client" -newkey rsa:4096 -days 365 -nodes -keyout $MYSQL_CLIENT_KEY_FILE -out $MYSQL_CLIENT_CSR_FILE;
# generate client cert
openssl rsa -in $MYSQL_CLIENT_KEY_FILE -out $MYSQL_CLIENT_CERT_FILE;
# use ca cert to sign the client cert
openssl x509 -req -in $MYSQL_CLIENT_CSR_FILE -days 365 -CA $MYSQL_CA_CERT_FILE -CAkey $MYSQL_CA_KEY_FILE -CAcreateserial -out $MYSQL_CLIENT_CERT_FILE;

echo -e "\n>> export certificates to p12 format\n"
# export certs
echo -e "export $MYSQL_CA_CERT_FILE"
openssl pkcs12 -export -clcerts -in $MYSQL_CA_CERT_FILE -password pass:12123123 -inkey $MYSQL_CA_KEY_FILE -out $MYSQL_CA_P12_FILE ;
echo -e "\nexport $MYSQL_SERVER_CERT_FILE"
openssl pkcs12 -export -clcerts -in $MYSQL_SERVER_CERT_FILE -password pass:12123123 -inkey $MYSQL_SERVER_KEY_FILE -out $MYSQL_SERVER_P12_FILE;
echo -e "\nexport $MYSQL_CLIENT_CERT_FILE"
openssl pkcs12 -export -clcerts -in $MYSQL_CLIENT_CERT_FILE -password pass:12123123 -inkey $MYSQL_CLIENT_KEY_FILE -out $MYSQL_CLIENT_P12_FILE;

echo -e "\n>> change privileges of keys and certificates\n"
# modify certs' privileges
chmod -v 0644 $MYSQL_CA_KEY_FILE $MYSQL_SERVER_KEY_FILE $MYSQL_CLIENT_KEY_FILe
chmod -v 0644 $MYSQL_CA_CERT_FILE $MYSQL_SERVER_CERT_FILE $MYSQL_CLIENT_CERT_FILE

echo -e "\n 【Finished】"
