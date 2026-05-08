package zerotrust

import future.keywords.in

# ============================================================================
# Default DENY — Core Zero Trust principle
# ============================================================================
default allow := false

# ----------------------------------------------------------------------------
# Network admins: full access to network resources
# ----------------------------------------------------------------------------
allow {
    user_has_role("network-admin")
    input.resource.type == "network"
}

# ----------------------------------------------------------------------------
# Security admins: access security and monitoring
# ----------------------------------------------------------------------------
allow {
    user_has_role("security-admin")
    input.resource.type in {"security", "monitoring", "policy"}
}

# ----------------------------------------------------------------------------
# Network operators: read-only network access
# ----------------------------------------------------------------------------
allow {
    user_has_role("network-operator")
    input.resource.type == "network"
    input.action in {"read", "list", "get"}
}

# ----------------------------------------------------------------------------
# Security analysts: read monitoring data only
# ----------------------------------------------------------------------------
allow {
    user_has_role("security-analyst")
    input.resource.type == "monitoring"
    input.action in {"read", "list", "search"}
}

# ----------------------------------------------------------------------------
# Auditors: read-only everywhere
# ----------------------------------------------------------------------------
allow {
    user_has_role("auditor")
    input.action in {"read", "list", "get", "audit"}
}

# ----------------------------------------------------------------------------
# Same-zone communication allowed inside management/monitoring
# ----------------------------------------------------------------------------
allow {
    input.source.zone == input.destination.zone
    input.source.zone in {"management", "monitoring"}
}

# ----------------------------------------------------------------------------
# Helper: check whether a user has a given role
# ----------------------------------------------------------------------------
user_has_role(role) { role in input.user.roles }

# ----------------------------------------------------------------------------
# Decision reasons (forwarded to ELK for forensic analysis)
# ----------------------------------------------------------------------------
reasons[msg] {
    not allow
    msg := sprintf("DENIED: user=%s resource=%s action=%s",
        [input.user.name, input.resource.name, input.action])
}

reasons[msg] {
    allow
    msg := sprintf("GRANTED: user=%s resource=%s action=%s",
        [input.user.name, input.resource.name, input.action])
}
