#!/bin/bash
# ============================================================================
# Zero Trust Service Health Check
# ============================================================================

echo '=== ZERO TRUST SERVICE HEALTH CHECK ==='
echo ''

echo -n '1. Vault:         '
curl -s http://localhost:8200/v1/sys/health | jq -r '.initialized' 2>/dev/null || echo 'unreachable'

echo -n '2. Keycloak:      '
curl -s http://localhost:8080/health 2>/dev/null | jq -r '.status' 2>/dev/null || echo 'starting...'

echo -n '3. OPA:           '
curl -s http://localhost:8282/health | jq -r 'if .status then .status else "ok" end' 2>/dev/null || echo 'unreachable'

echo -n '4. ONOS:          '
curl -s -u karaf:karaf http://localhost:8181/onos/v1/applications 2>/dev/null | \
    jq -r '.applications | length | tostring + " apps"' 2>/dev/null || echo 'starting...'

echo -n '5. Elasticsearch: '
curl -s http://localhost:9200/_cluster/health | jq -r '.status' 2>/dev/null || echo 'unreachable'

echo -n '6. Kibana:        '
curl -s -o /dev/null -w '%{http_code}' http://localhost:5601 2>/dev/null
echo ''

echo ''
echo 'Expected: true, UP, ok, X apps, green/yellow, 200'
