#!/bin/bash

set -e

SSL_DIR="/ssl"
VALIDITY_DAYS=365
KEYSTORE_PASSWORD="password123"
TRUSTSTORE_PASSWORD="password123"
KEY_PASSWORD="password123"

# Create required directories
mkdir -p $SSL_DIR
mkdir -p /scripts

# Change to SSL directory
cd $SSL_DIR

# Clean up any existing files
rm -f *.jks *.p12 *-key *-cert *-csr ca-cert.srl *_creds *.conf

# Create CA private key
openssl genrsa -out ca-key 2048

# Create CA certificate
openssl req -new -x509 -key ca-key -out ca-cert -days $VALIDITY_DAYS -subj "/C=US/ST=CA/L=SF/O=TestOrg/OU=TestOU/CN=TestCA"

# Create server private key
openssl genrsa -out server-key 2048

# Create server certificate signing request
openssl req -new -key server-key -out server-csr -subj "/C=US/ST=CA/L=SF/O=TestOrg/OU=TestOU/CN=kafka-server"

# Create server certificate signed by CA
openssl x509 -req -in server-csr -CA ca-cert -CAkey ca-key -CAcreateserial -out server-cert -days $VALIDITY_DAYS

# Create client private key
openssl genrsa -out client-key 2048

# Create client certificate signing request
openssl req -new -key client-key -out client-csr -subj "/C=US/ST=CA/L=SF/O=TestOrg/OU=TestOU/CN=kafka-client"

# Create client certificate signed by CA
openssl x509 -req -in client-csr -CA ca-cert -CAkey ca-key -CAcreateserial -out client-cert -days $VALIDITY_DAYS

# Create server keystore
keytool -keystore kafka.server.keystore.jks -alias kafka-server -validity $VALIDITY_DAYS -genkey -keyalg RSA -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD -dname "CN=kafka-server,OU=TestOU,O=TestOrg,L=SF,S=CA,C=US"

# Delete default certificate from keystore
keytool -keystore kafka.server.keystore.jks -alias kafka-server -delete -storepass $KEYSTORE_PASSWORD

# Import CA certificate to keystore
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass $KEYSTORE_PASSWORD -noprompt

# Create PKCS12 file from server key and certificate
openssl pkcs12 -export -in server-cert -inkey server-key -out server.p12 -name kafka-server -CAfile ca-cert -caname root -password pass:$KEY_PASSWORD

# Import server certificate to keystore
keytool -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEY_PASSWORD -destkeystore kafka.server.keystore.jks -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass $KEY_PASSWORD -alias kafka-server

# Create server truststore
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $TRUSTSTORE_PASSWORD -noprompt

# Create client keystore
keytool -keystore kafka.client.keystore.jks -alias kafka-client -validity $VALIDITY_DAYS -genkey -keyalg RSA -storepass $KEYSTORE_PASSWORD -keypass $KEY_PASSWORD -dname "CN=kafka-client,OU=TestOU,O=TestOrg,L=SF,S=CA,C=US"

# Delete default certificate from client keystore
keytool -keystore kafka.client.keystore.jks -alias kafka-client -delete -storepass $KEYSTORE_PASSWORD

# Import CA certificate to client keystore
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass $KEYSTORE_PASSWORD -noprompt

# Create PKCS12 file from client key and certificate
openssl pkcs12 -export -in client-cert -inkey client-key -out client.p12 -name kafka-client -CAfile ca-cert -caname root -password pass:$KEY_PASSWORD

# Import client certificate to client keystore
keytool -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEY_PASSWORD -destkeystore kafka.client.keystore.jks -srckeystore client.p12 -srcstoretype PKCS12 -srcstorepass $KEY_PASSWORD -alias kafka-client

# Create client truststore
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass $TRUSTSTORE_PASSWORD -noprompt

# Create credential files
echo $KEYSTORE_PASSWORD > kafka_keystore_creds
echo $KEY_PASSWORD > kafka_ssl_key_creds
echo $TRUSTSTORE_PASSWORD > kafka_truststore_creds

# Create JAAS configuration file for Kafka server
cat > kafka_server_jaas.conf << EOF
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="admin123"
    user_admin="admin123"
    user_client="client123";
};

Client {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="admin123";
};
EOF

echo "SSL certificates and keystores generated successfully!"

# Set permissions
chmod 644 *.jks
chmod 644 *_creds
chmod 644 *.conf