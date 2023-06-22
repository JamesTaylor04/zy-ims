#!/bin/bash

read -e -p "Please enter the domain name? " HOST

ROOT_DIR=/root/docker-certs
CURRENT_DATETIME=`date +%Y-%m-%d_%H:%M:%S`
SAVE_DIR=$ROOT_DIR/$CURRENT_DATETIME/$HOST
PKCS12_EXPORT_PASSWORD=12123123
KEY_PASSWORD=Apple$385400P@ssw0rd

DOCKER_CA_KEY_FILE=$SAVE_DIR/ca-key.pem
DOCKER_CA_CERT_FILE=$SAVE_DIR/ca.pem
DOCKER_CA_P12_FILE=$SAVE_DIR/ca.p12

DOCKER_SERVER_CNF_FILE=$SAVE_DIR/docker.cnf
DOCKER_SERVER_CONFIG_FILE=$ROOT_DIR/docker-server.cnf
DOCKER_SERVER_KEY_FILE=$SAVE_DIR/docker-key.pem
DOCKER_SERVER_CSR_FILE=$SAVE_DIR/docker-req.csr
DOCKER_SERVER_CERT_FILE=$SAVE_DIR/docker-cert.pem
DOCKER_SERVER_P12_FILE=$SAVE_DIR/docker-cert.p12

DOCKER_CLIENT_CNF_FILE=$SAVE_DIR/docker-client.cnf
DOCKER_CLIENT_KEY_FILE=$SAVE_DIR/docker-client-key.pem
DOCKER_CLIENT_CSR_FILE=$SAVE_DIR/docker-client-req.csr
DOCKER_CLIENT_CERT_FILE=$SAVE_DIR/docker-client-cert.pem
DOCKER_CLIENT_P12_FILE=$SAVE_DIR/docker-client-cert.p12

if [ $HOST != "" ]; then
	# read variables from user
	read -e -p "enter host ip:" HOST_IP
	read -e -p "Enter docker client name: " DOCKER_CLIENT_NAME

	echo -e "\n"
	# create directory
	echo -e "\n>> create save directory"
	mkdir -p $SAVE_DIR

	echo -e "\n>>create ca certificate"
	# 生成ca键
	openssl genrsa -aes256 -out $DOCKER_CA_KEY_FILE 4096;
	# 生成ca证书
	openssl req -subj "/C=CN/ST=Shanghai/L=SH/O=My\ Group/OU=Java\ Development\ Team/CN=$HOST" -new -x509 -days 365 -passin pass:Apple$385400P@ssw0rd -key $DOCKER_CA_KEY_FILE -sha256 -out $DOCKER_CA_CERT_FILE;

	echo -e "\n>> create server certificate"
	# 生成服务器私钥
	openssl genrsa -out $DOCKER_SERVER_KEY_FILE 4096;
	# 生成服务端证书配置文件
	echo subjectAltName = DNS:$HOST,IP:$HOST_IP >> $DOCKER_SERVER_CNF_FILE;
	echo extendedKeyUsage = serverAuth >> $DOCKER_SERVER_CNF_FILE;
	# 生成服务器证书请求
	openssl req -subj "/CN=$HOST" -sha256 -new -key $DOCKER_SERVER_KEY_FILE -out $DOCKER_SERVER_CSR_FILE;

	# 使用CA证书签发服务器证书
	openssl x509 -req -days 365 -sha256 -in $DOCKER_SERVER_CSR_FILE -passin pass:Apple$385400P@ssw0rd -CA $DOCKER_CA_CERT_FILE -CAkey $DOCKER_CA_KEY_FILE -CAcreateserial -out $DOCKER_SERVER_CERT_FILE -extfile $DOCKER_SERVER_CNF_FILE

	echo -e "\n>> create client certificate\n"
	# 生成客户端私钥
	openssl genrsa -out $DOCKER_CLIENT_KEY_FILE 4096
	# 生成客户端证书请求
	openssl req -subj "/CN=$DOCKER_CLIENT_NAME" -key $DOCKER_CLIENT_KEY_FILE -new -sha256 -out $DOCKER_CLIENT_CSR_FILE;
	# 生成客户端证书配置文件
	echo extendedKeyUsage = clientAuth >> $DOCKER_CLIENT_CNF_FILE
	# 使用CA证书签发客户端证书
	openssl x509 -req -days 365 -sha256 -in $DOCKER_CLIENT_CSR_FILE -passin pass:Apple$385400P@ssw0rd -CA $DOCKER_CA_CERT_FILE -CAkey $DOCKER_CA_KEY_FILE -CAcreateserial -out $DOCKER_CLIENT_CERT_FILE -extfile $DOCKER_CLIENT_CNF_FILE

	echo -e "\n>> export certificates to p12 format\n"
	# 导出证书为PKCS12格式
	echo -e "export $DOCKER_CA_CERT_FILE"
	openssl pkcs12 -export -clcerts -in $DOCKER_CA_CERT_FILE -password pass:12123123 -passin pass:Apple$385400P@ssw0rd -inkey $DOCKER_CA_KEY_FILE -out $DOCKER_CA_P12_FILE ;
	echo -e "\nexport $DOCKER_SERVER_CERT_FILE"
	openssl pkcs12 -export -clcerts -in $DOCKER_SERVER_CERT_FILE -password pass:12123123 -inkey $DOCKER_SERVER_KEY_FILE -out $DOCKER_SERVER_P12_FILE;
	echo -e "\nexport $DOCKER_CLIENT_CERT_FILE"
	openssl pkcs12 -export -clcerts -in $DOCKER_CLIENT_CERT_FILE -password pass:12123123 -inkey $DOCKER_CLIENT_KEY_FILE -out $DOCKER_CLIENT_P12_FILE;

	echo -e "\n>> change privileges of keys and certificates\n"
	# 修改证书权限
	chmod -v 0400 $DOCKER_CA_KEY_FILE $DOCKER_SERVER_KEY_FILE $DOCKER_CLIENT_KEY_FILe
	chmod -v 0444 $DOCKER_CA_CERT_FILE $DOCKER_SERVER_CERT_FILE $DOCKER_CLIENT_CERT_FILE

	echo -e "\n 【Finished】"
	
else
	echo "You should provide the domain name!"
fi



