#!/bin/bash
# ============================================================================
# Keycloak Bootstrap
# ============================================================================
# Creates:
#   - The 'zero-trust' realm with brute-force protection and short-lived tokens
#   - The 'onos-controller' OIDC client
#   - Five Zero Trust roles
#   - A test user 'netadmin' with the network-admin role
# ============================================================================

set -e

echo '=== [1/5] Waiting for Keycloak to be healthy ==='
until curl -sf http://localhost:8080/health > /dev/null; do
    echo 'Waiting for Keycloak...'
    sleep 5
done

echo '=== [2/5] Getting admin token ==='
TOKEN=$(curl -s -X POST \
    'http://localhost:8080/realms/master/protocol/openid-connect/token' \
    -d 'username=admin&password=ZtK3ycl0ak!2024&grant_type=password&client_id=admin-cli' \
    | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo 'ERROR: failed to get admin token. Check Keycloak admin credentials.'
    exit 1
fi

echo '=== [3/5] Creating zero-trust realm ==='
curl -s -X POST 'http://localhost:8080/admin/realms' \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{
        "realm":"zero-trust",
        "enabled":true,
        "bruteForceProtected":true,
        "failureFactor":5,
        "passwordPolicy":"length(12) and upperCase(1) and digits(1)",
        "accessTokenLifespan":300
    }'

echo '=== [4/5] Creating onos-controller OIDC client ==='
curl -s -X POST 'http://localhost:8080/admin/realms/zero-trust/clients' \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{
        "clientId":"onos-controller",
        "enabled":true,
        "clientAuthenticatorType":"client-secret",
        "secret":"onos-secret-change-me",
        "directAccessGrantsEnabled":true,
        "serviceAccountsEnabled":true,
        "protocol":"openid-connect"
    }'

echo '=== [5/5] Creating roles and test user ==='
for R in network-admin security-admin network-operator security-analyst auditor; do
    curl -s -X POST 'http://localhost:8080/admin/realms/zero-trust/roles' \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        -d "{\"name\":\"$R\"}"
done

curl -s -X POST 'http://localhost:8080/admin/realms/zero-trust/users' \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{
        "username":"netadmin",
        "enabled":true,
        "credentials":[{"type":"password","value":"NetAdmin!2024#","temporary":false}]
    }'

UID=$(curl -s 'http://localhost:8080/admin/realms/zero-trust/users?username=netadmin' \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

RREP=$(curl -s 'http://localhost:8080/admin/realms/zero-trust/roles/network-admin' \
    -H "Authorization: Bearer $TOKEN")

curl -s -X POST "http://localhost:8080/admin/realms/zero-trust/users/$UID/role-mappings/realm" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d "[$RREP]"

echo ''
echo 'KEYCLOAK SETUP COMPLETE!'
echo 'Test user: netadmin / NetAdmin!2024#'
