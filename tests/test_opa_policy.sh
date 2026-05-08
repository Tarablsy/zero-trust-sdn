#!/bin/bash
# ============================================================================
# OPA Policy Validation Test
# ============================================================================
# Tests the Zero Trust Rego policy against ten role-resource-action cases
# and reports PASS or FAIL for each case.
# ============================================================================

OPA_URL='http://localhost:8282/v1/data/zerotrust/allow'

test_policy() {
    local desc=$1 role=$2 res_type=$3 action=$4 expected=$5

    RESULT=$(curl -s -X POST $OPA_URL -H 'Content-Type: application/json' \
        -d "{\"input\":{\"user\":{\"name\":\"test\",\"roles\":[\"$role\"]},
            \"resource\":{\"type\":\"$res_type\",\"name\":\"test\"},
            \"action\":\"$action\",
            \"source\":{\"zone\":\"management\"},
            \"destination\":{\"zone\":\"controller\"}}}" | jq -r '.result')

    if [ "$RESULT" == "$expected" ]; then
        echo "PASS: $desc -> $RESULT"
    else
        echo "FAIL: $desc -> Expected $expected, Got $RESULT"
    fi
}

echo '=== OPA Policy Validation ==='
test_policy 'admin write network'    'network-admin'    'network'    'write' 'true'
test_policy 'admin write security'   'network-admin'    'security'   'write' 'false'
test_policy 'sec-admin write sec'    'security-admin'   'security'   'write' 'true'
test_policy 'operator write net'     'network-operator' 'network'    'write' 'false'
test_policy 'operator read net'      'network-operator' 'network'    'read'  'true'
test_policy 'analyst write monitor'  'security-analyst' 'monitoring' 'write' 'false'
test_policy 'analyst read monitor'   'security-analyst' 'monitoring' 'read'  'true'
test_policy 'auditor read network'   'auditor'          'network'    'read'  'true'
test_policy 'no-role read anything'  ''                 'network'    'read'  'false'
test_policy 'unknown role write'     'hacker'           'network'    'write' 'false'
