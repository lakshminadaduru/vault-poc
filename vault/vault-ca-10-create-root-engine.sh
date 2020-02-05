# ########################################
# Loading variables
# ########################################

source ./vault-ca-00-common-variables.sh

# ########################################
# Step 1: Generate Root CA
# ########################################

echo "Step1-10: First, enable the $VAULT_ROOT_PKI_NAME secrets engine at $VAULT_ROOT_PKI_NAME path using /sys/mounts endpoint"

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data '{"type":"pki"}' \
       $VAULT_ADDR/v1/sys/mounts/$VAULT_ROOT_PKI_NAME

echo "Step1-20: Tune the $VAULT_ROOT_PKI_NAME secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours."

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data '{"max_lease_ttl":"87600h"}' \
       $VAULT_ADDR/v1/sys/mounts/$VAULT_ROOT_PKI_NAME/tune

echo "Step1-30: Generate the root certificate and extract the CA certificate and save it as CA_cert.crt"

tee Step1-30.root_cert.request.json <<EOF
{
  "common_name": "$VAULT_ROOT_COMMON_NAME",
  "ttl": "87600h"
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data @Step1-30.root_cert.request.json \
       $VAULT_ADDR/v1/$VAULT_ROOT_PKI_NAME/root/generate/internal \
       > Step1-30.root_cert.response.json

cat Step1-30.root_cert.response.json | jq

cat Step1-30.root_cert.response.json | jq -r ".data.certificate" > $VAULT_ROOT_CERTIFICATE_CRT_FILE
cat Step1-30.root_cert.response.json | jq -r ".data.private_key" > $VAULT_ROOT_CERTIFICATE_KEY_FILE
cat Step1-30.root_cert.response.json | jq -r ".data.serial_number" > $VAULT_ROOT_CERTIFICATE_SERIAL_FILE


echo "Step1-40: Configure the CA and CRL URLs:"

tee Step1-40.config_root_pki.request.json <<EOF
{
  "issuing_certificates": "$VAULT_ADDR/v1/$VAULT_ROOT_PKI_NAME/ca",
  "crl_distribution_points": "$VAULT_ADDR/v1/$VAULT_ROOT_PKI_NAME/crl"
}
EOF

curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data @Step1-40.config_root_pki.request.json \
       $VAULT_ADDR/v1/$VAULT_ROOT_PKI_NAME/config/urls

