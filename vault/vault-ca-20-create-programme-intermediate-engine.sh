# ########################################
# Loading variables
# ########################################

source ./vault-ca-00-common-variables.sh

# ########################################
# Step 2: Generate Intermediate CA
# ########################################


echo "Step2-10: First, enable the pki secrets engine at $VAULT_INTERMEDIATE_PKI_NAME path"
curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data '{"type":"pki"}' \
       $VAULT_ADDR/v1/sys/mounts/$VAULT_INTERMEDIATE_PKI_NAME


echo "Step2-20: Tune the $VAULT_INTERMEDIATE_PKI_NAME secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours."
curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data '{"max_lease_ttl":"43800h"}' \
       $VAULT_ADDR/v1/sys/mounts/$VAULT_INTERMEDIATE_PKI_NAME/tune


echo "Step2-30:  Generate an intermediate using the /$VAULT_INTERMEDIATE_PKI_NAME/intermediate/generate/internal endpoint."
tee intermediate_cert.request.json <<EOF
{
  "common_name": "$VAULT_INTERMEDIATE_COMMON_NAME"
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data @intermediate_cert.request.json \
       $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/intermediate/generate/internal > intermediate_cert.response.json


echo "Step2-40: Sign the intermediate certificate with the root certificate and save the certificate as intermediate.cert.pem."
CSR_TMP=$(cat intermediate_cert.response.json | jq ".data.csr")

tee sign_intermediate.request.json <<EOF
{
  "csr": $CSR_TMP,
  "format": "pem_bundle",
  "ttl": "43800h"
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data @sign_intermediate.request.json \
       $VAULT_ADDR/v1/$VAULT_ROOT_PKI_NAME/root/sign-intermediate | jq > sign_intermediate.response.json


echo "Step2-50: Once the CSR is signed and the root CA returns a certificate, it can be imported back into Vault using the /$VAULT_INTERMEDIATE_PKI_NAME/intermediate/set-signed endpoint."
TMP_INTERMEDIATE_CERTIFICATE=$(cat sign_intermediate.response.json | jq ".data.certificate")

tee import_intermediate_signed.request.json <<EOF
{
  "certificate": $TMP_INTERMEDIATE_CERTIFICATE
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
        --request POST \
        --data @import_intermediate_signed.request.json \
        $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/intermediate/set-signed


echo "Generating intermediate certificates files"

cat sign_intermediate.response.json | jq -r ".data.certificate" > $INTERMEDIATE_CERTIFICATE_CRT_FILE
cat sign_intermediate.response.json | jq -r ".data.private_key" > $INTERMEDIATE_CERTIFICATE_KEY_FILE
cat sign_intermediate.response.json | jq -r ".data.issuing_ca" > $INTERMEDIATE_CERTIFICATE_ISSUINGCA_FILE
cat sign_intermediate.response.json | jq -r ".data.serial_number" > $INTERMEDIATE_CERTIFICATE_SERIAL_FILE

openssl x509 -in $INTERMEDIATE_CERTIFICATE_CRT_FILE -out $INTERMEDIATE_CERTIFICATE_CRT_FILE".pem" -outform PEM

echo "Intermediate cert validation"
openssl x509 -modulus -noout -in $INTERMEDIATE_CERTIFICATE_CRT_FILE | openssl md5
echo "Intermediate key validation"
openssl rsa -check -noout -in $INTERMEDIATE_CERTIFICATE_KEY_FILE | openssl md5


#cat myorg_pocs_dev.crt root_CA_myorg.crt > intermediate.bundle.crt
echo "Generate bundle client certificate"
cat $INTERMEDIATE_CERTIFICATE_CRT_FILE $VAULT_ROOT_CERTIFICATE_CRT_FILE > $INTERMEDIATE_CERTIFICATE_CRT_FILE_BUNDLE

# ########################################
# Step 2: Create a Role
# ########################################

#Create a role named $VAULT_ROLE_NAME which allows subdomains.
#one year TTL

echo "Creating role inside intermediate pki engine."

tee create_role.request.json <<EOF
{
  "allowed_domains": "$VAULT_ROLE_ALLOWED_DOMAINS",
  "allow_subdomains": true,
  "max_ttl": "8760h"
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data @create_role.request.json \
       $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/roles/$VAULT_ROLE_NAME


# ########################################
# Step 2: K8S Namespace
# ########################################

echo "creating kubernetes namespace."

tee create_namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $K8S_NAMESPACE_NAME
  labels:
    istio-injection: enabled
    environment: $VAULT_ENVIRONMENT
    programme: $VAULT_PROGRAMME
    tier: internal
EOF

kubectl apply -f create_namespace.yaml

# ########################################
# Step 2: K8S Service Account
# ########################################

echo "Creating kubernetes SA for namespace"

tee create_sa.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_NAMESPACE_NAME
  namespace: $K8S_NAMESPACE_NAME
EOF

kubectl apply -f create_sa.yaml

# ########################################
# Step 2: Importing intermediate certificate
# ########################################

echo "Storing intermediate certificates into K8S as secret"

kubectl create -n $K8S_NAMESPACE_NAME secret generic $K8S_INTERMEDIATE_SECRET_NAME \
--from-file=issuingca=$INTERMEDIATE_CERTIFICATE_ISSUINGCA_FILE \
--from-file=cert=$INTERMEDIATE_CERTIFICATE_CRT_FILE \
--from-file=key=$INTERMEDIATE_CERTIFICATE_KEY_FILE \
--from-file=serial=$INTERMEDIATE_CERTIFICATE_SERIAL_FILE

