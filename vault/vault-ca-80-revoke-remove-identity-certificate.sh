# ########################################
# Loading variables
# ########################################

source ./vault-ca-00-common-variables.sh

# ########################################
# Step 5: Revoke Certificates
# ########################################

#Invoke the /$VAULT_INTERMEDIATE_PKI_NAME/revoke endpoint to invoke a certificate using its serial number.

TMP_SERIAL_NUMBER=$(cat $IDENTITY_CERTIFICATE_SERIAL_FILE)

echo "Revoking certificate - $IDENTITY_CERTIFICATE_SERIAL_FILE"
curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data "{\"serial_number\": \"$TMP_SERIAL_NUMBER\"}" \
       $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/revoke > revoke.response.json


# ########################################
# Step 6: Remove Expired Certificates
# ########################################

echo "Removing expired certificates from $VAULT_INTERMEDIATE_PKI_NAME"
curl --header "X-Vault-Token: $VAULT_DEV_ROOT_TOKEN_ID" \
       --request POST \
       --data '{"tidy_cert_store": true, "tidy_revoked_certs": true}' \
       $VAULT_ADDR/v1/$VAULT_INTERMEDIATE_PKI_NAME/tidy > tidy.response.json
