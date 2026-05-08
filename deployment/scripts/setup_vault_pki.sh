#!/bin/bash
# ============================================================================
# Vault PKI Bootstrap
# ============================================================================
# Builds the two-tier PKI hierarchy:
#   - Root CA (4096-bit, 10 years)
#   - Intermediate CA (4096-bit, 5 years)
#   - 3 certificate roles: sdn-controller, security-services, network-endpoint
# ============================================================================

set -e

export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='zt-root-token-2024'

echo '=== [1/4] Enabling Root CA at /pki ==='
vault secrets enable -path=pki pki
vault secrets tune -max-lease-ttl=87600h pki

vault write pki/root/generate/internal \
    common_name='Zero Trust Lab Root CA' \
    ttl=87600h \
    key_bits=4096

vault write pki/config/urls \
    issuing_certificates='http://172.20.0.20:8200/v1/pki/ca' \
    crl_distribution_points='http://172.20.0.20:8200/v1/pki/crl'

echo '=== [2/4] Enabling Intermediate CA at /pki_int ==='
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

vault write pki_int/intermediate/generate/internal \
    common_name='Zero Trust Lab Intermediate CA' \
    key_bits=4096 \
    -format=json | jq -r '.data.csr' > /tmp/int-ca.csr

vault write pki/root/sign-intermediate \
    csr=@/tmp/int-ca.csr \
    format=pem_bundle \
    ttl=43800h \
    -format=json | jq -r '.data.certificate' > /tmp/int-signed.pem

vault write pki_int/intermediate/set-signed certificate=@/tmp/int-signed.pem

echo '=== [3/4] Creating certificate roles ==='
vault write pki_int/roles/sdn-controller \
    allowed_domains='zt-onos,controller.zt.local' \
    allow_bare_domains=true \
    allow_ip_sans=true \
    max_ttl=24h \
    key_bits=2048

vault write pki_int/roles/security-services \
    allowed_domains='zt-vault,zt-keycloak,zt-opa,security.zt.local' \
    allow_bare_domains=true \
    allow_ip_sans=true \
    max_ttl=72h

vault write pki_int/roles/network-endpoint \
    allowed_domains='endpoint.zt.local' \
    allow_subdomains=true \
    allow_ip_sans=true \
    max_ttl=8h

echo '=== [4/4] Test: issuing a certificate ==='
vault write pki_int/issue/sdn-controller \
    common_name='zt-onos' \
    ip_sans='172.20.0.11' \
    ttl=24h \
    -format=json | jq '.data.certificate' | head -3

echo ''
echo 'PKI SETUP COMPLETE!'
