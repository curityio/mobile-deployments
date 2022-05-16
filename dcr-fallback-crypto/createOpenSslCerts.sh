#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Point to OpenSSL
#
case "$(uname -s)" in

  Darwin)
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  MINGW64*)
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;
esac

#
# Issuer parameters
#
ROOT_CERT_FILE_PREFIX='DeviceAuthority'
ROOT_CERT_DESCRIPTION='Curity Test Device Authority'

#
# Client certificate fields
#
CLIENT_CERT_NAME='DeviceClientCert'
CLIENT_CERT_FILE_PREFIX='DeviceClientCert'
CLIENT_CERT_PASSWORD='android'

#
# Create a root certificate authority
#
openssl genrsa -out $ROOT_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created Root CA key'

openssl req \
    -x509 \
    -new \
    -nodes \
    -key $ROOT_CERT_FILE_PREFIX.key \
    -out $ROOT_CERT_FILE_PREFIX.pem \
    -subj "/CN=$ROOT_CERT_DESCRIPTION" \
    -reqexts v3_req \
    -extensions v3_ca \
    -sha256 \
    -days 3650
echo '*** Successfully created Root CA'

#
# Create the client certificate to send to the Identity Server as a DCR credential
#
openssl genrsa -out $CLIENT_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created client key'

openssl req \
    -new \
    -key $CLIENT_CERT_FILE_PREFIX.key \
    -out $CLIENT_CERT_FILE_PREFIX.csr \
    -subj "/CN=$CLIENT_CERT_NAME"
echo '*** Successfully created client certificate signing request'

openssl x509 -req \
    -in $CLIENT_CERT_FILE_PREFIX.csr \
    -CA $ROOT_CERT_FILE_PREFIX.pem \
    -CAkey $ROOT_CERT_FILE_PREFIX.key \
    -CAcreateserial \
    -out $CLIENT_CERT_FILE_PREFIX.pem \
    -sha256 \
    -days 365 \
    -extensions client_ext \
    -extfile extensions.cnf
echo '*** Successfully created client certificate'

openssl pkcs12 \
    -export -inkey $CLIENT_CERT_FILE_PREFIX.key \
    -in $CLIENT_CERT_FILE_PREFIX.pem \
    -name $CLIENT_CERT_NAME \
    -out $CLIENT_CERT_FILE_PREFIX.p12 \
    -passout pass:$CLIENT_CERT_PASSWORD
echo '*** Successfully exported client certificate to a PKCS#12 file'

# Remove temporary files
rm $CLIENT_CERT_FILE_PREFIX.csr
rm $ROOT_CERT_FILE_PREFIX.srl