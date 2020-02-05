# ########################################
# Loading variables
# ########################################

source ./vault-ca-00-common-variables.sh

# ########################################
# Step 4: Request Certificates
# ########################################

#Invoke the /$VAULT_INTERMEDIATE_PKI_NAME/issue/<role_name> endpoint to request a new certificate.
#Request a certificate for the test.example.com domain based on the $VAULT_ROLE_NAME role:

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data "{\"common_name\": \"$VAULT_IDENTITY_CERTIFICATE_COMMON_NAME\", \"ttl\": \"8760h\"}" \
       $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/issue/$VAULT_ROLE_NAME > $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE

echo "Generating certificate file ($IDENTITY_CERTIFICATE_CRT_FILE)"
cat $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE | jq -r ".data.certificate" > $IDENTITY_CERTIFICATE_CRT_FILE
echo "Validating certificate"
openssl x509 -modulus -noout -in $IDENTITY_CERTIFICATE_CRT_FILE | openssl md5
HASH_IDENTITY_CERTIFICATE=$(openssl x509 -in $IDENTITY_CERTIFICATE_CRT_FILE -pubkey -noout -outform pem | sha256sum)
echo "Hash Identity certificate $HASH_IDENTITY_CERTIFICATE"

echo "Generating private key file ($IDENTITY_CERTIFICATE_KEY_FILE)"
cat $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE | jq -r ".data.private_key" > $IDENTITY_CERTIFICATE_KEY_FILE
echo "Validating key"
openssl rsa -check -noout -in $IDENTITY_CERTIFICATE_KEY_FILE | openssl md5
HASH_IDENTITY_KEY=$(openssl pkey -in $IDENTITY_CERTIFICATE_KEY_FILE -pubout -outform pem | sha256sum)
echo "Hash Identity key $HASH_IDENTITY_KEY"

if [[ "$HASH_IDENTITY_CERTIFICATE" == "$HASH_IDENTITY_KEY" ]]; then
    echo "Hash are equal. CERTIFICATE AND PRIVATE KEY ARE VALID."
else
    echo "Hash are not equal. CERTIFICATE AND PRIVATE KEY ARE INVALID, PLEASE REVIEW THE GENERATION PROCESS."
    exit -1
fi

echo "Generating serial number file $IDENTITY_CERTIFICATE_SERIAL_FILE"
cat $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE | jq -r ".data.serial_number" > $IDENTITY_CERTIFICATE_SERIAL_FILE

echo "Generating CA CHAIN $IDENTITY_CERTIFICATE_CA_CHAIN_FILE"
cat $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE | jq -r ".data.ca_chain[0]" > $IDENTITY_CERTIFICATE_CA_CHAIN_FILE

echo "Generating issuing ca file $IDENTITY_CERTIFICATE_ISSUING_CA_FILE"
cat $IDENTITY_CERTIFICATE_VAULT_RESPONSE_FILE | jq -r ".data.issuing_ca" > $IDENTITY_CERTIFICATE_ISSUING_CA_FILE

echo "Generating SSL_CERT file $IDENTITY_CERTIFICATE_SSL_CERT_FILE"
cat $IDENTITY_CERTIFICATE_CRT_FILE > $IDENTITY_CERTIFICATE_SSL_CERT_FILE
cat $IDENTITY_CERTIFICATE_ISSUING_CA_FILE >> $IDENTITY_CERTIFICATE_SSL_CERT_FILE


# ########################################
# Step 4: Import Identity certificate into K8S namespace
# ########################################

echo "Registering identity certificate into K8S namespace"

kubectl create -n istio-system secret generic $K8S_IDENTITY_SECRET_NAME \
--from-file=key=./vault/tmp/$IDENTITY_CERTIFICATE_KEY_FILE \
--from-file=cert=./vault/tmp/$IDENTITY_CERTIFICATE_SSL_CERT_FILE \
--from-file=cacert=./vault/tmp/$INTERMEDIATE_CERTIFICATE_CRT_FILE_BUNDLE \
--from-file=serial=./vault/tmp/$IDENTITY_CERTIFICATE_SERIAL_FILE


#kubectl create -n istio-system secret generic httpbin-dev-pocs-myorg-com-mtls-secret \
#--from-file=key=./vault/tmp/httpbin-dev-pocs-myorg-com.key \
#--from-file=cert=./vault/tmp/httpbin-dev-pocs-myorg-com.ssl_cert \
#--from-file=cacert=./vault/tmp/myorg_pocs_dev.crt.bundle \
#--from-file=serial=./vault/tmp/httpbin-dev-pocs-myorg-com.serial


#openssl x509 -in $IDENTITY_CERTIFICATE_CRT_FILE -out $IDENTITY_CERTIFICATE_CRT_FILE".pem" -outform PEM