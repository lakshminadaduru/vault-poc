# HOW TO USE THE SCRIPTS

To run the scripts you must have a Hashicorp Vault server available, in development you can use a temporal Docker image.

Bellow a snippet to start a Vault server in development mode.
```
docker run --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:1234' -p 1234:1234  vault
```

After start visit
```
http://localhost:1234/ui/
```


## CREATE ROOT CA

In this section we are goint to:
- Create the ROOT CA authority (if does not exist)
  - Create a Root Vault Engine.
  - CA Cert.

Please follow next steps:
- Edit vault-ca-00-common-variables.sh file.
- Run vault-ca-10-create-root-engine.sh file.

## REGISTER A PROGRAMME+ENVIRONMENT

In this section we are goint to:
- Create an Intermediate Vault Engine to the programme+environment.
- Create a role inside the Intermediate Vault Engine per programme+enviroment.
- Create a Kubernetes namespace per programme+enviroment.
- Create a Kubernetes Service Account to the new Namespace

To create a programme, follow next steps:
- Edit vault-ca-00-common-variables.sh file.
- Run vault-ca-20-create-programme-intermediate-engine.sh file.


## CREATE AN IDENTITY CERTIFICATE (for a server)
In this section we are goint to:
- Create a new identity certificate in Vault.
- Register new certificate as Kubernetes secret inside the namespace associated.
-- Register certificate serial number inside k8s secret.

Please follow next steps:
- Edit vault-ca-00-common-variables.sh file.
- Run vault-ca-40-k8s-create-identity-certificate.sh file.


# REVOKE AND REMOVE EXPIRED CERTIFICATES
Revoke and remove certificates from Hashicorp Vault.

Please follow next steps:
- Edit vault-ca-00-common-variables.sh file.
- Run vault-ca-80-revoke-remove-identity-certificate.sh file.



# LINKS
- [Hashicorp Vault - PKI Secrets Engine API](https://www.vaultproject.io/api/secret/pki/index.html#read-ca-certificate)
- [Hashicorp Vault - Build Your Own Certificate Authority ](https://learn.hashicorp.com/vault/secrets-management/sm-pki-engine)
- [Istio Secure Gateways](https://istio.io/docs/tasks/traffic-management/ingress/secure-ingress-sds/)

