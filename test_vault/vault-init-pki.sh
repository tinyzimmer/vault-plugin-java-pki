#!/bin/bash

set -e

export VAULT_ADDR='http://127.0.0.1:8200'
vault login devroottoken

vault secrets enable -path=pki pki
vault secrets tune -max-lease-ttl=219000h pki

vault write -field=certificate pki/root/generate/internal \
    common_name="dev.vault.localhost" \
    exclude_cn_from_sans=true \
    ttl=215000h

# Register the plugin
SHASUM=$(sha256sum /vault/plugins/vault-plugin-java-pki | cut -d ' ' -f1)
vault write sys/plugins/catalog/java-pki \
  sha_256="${SHASUM}" \
  command=vault-plugin-java-pki

# Create the pki backend for kafka
vault secrets enable -path=pki_java java-pki
vault secrets tune -max-lease-ttl=210000h pki_java

# Create a CSR
csr=$(vault write -format=json pki_java/intermediate/generate/internal \
    common_name="Local Dev Intermediate" \
    ttl=209999h | jq -r '.data.csr')

# Sign the intermediate CSR
intermediate=$(vault write -format=json pki/root/sign-intermediate \
    csr="${csr}" \
    format=pem_bundle \
    ttl=209999h | jq -r '.data.certificate')

# write the signed cert back to kafka pki
vault write pki_java/intermediate/set-signed certificate="${intermediate}"

# Set information about the crl and so on
vault write pki_java/config/urls \
    issuing_certificates="http://dev.vault.localhost:8200/v1/pki_java/ca" \
    crl_distribution_points="http://dev.vault.localhost:8200/v1/pki_java/crl"

# Set the role which can sign certificates
vault write pki_java/roles/test \
    allowed_domains="dev.vault.localhost,vault.localhost" \
    allow_subdomains=true \
    allow_localhost=true \
    max_ttl=60000h \
    allow_any_name=true \
    allow_ip_sans=true \
    allow_glob_domains=true \
    organization="Testing" \
    use_csr_common_name=false \
    use_csr_sans=false
