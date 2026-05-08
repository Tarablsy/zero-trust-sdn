# Zero Trust Architecture for Software-Defined Networks

> A Docker-based implementation of a Zero Trust security framework for SDN, with Vulnerability Assessment, Countermeasures and Penetration Testing.

**Graduation Project 2 — Department of Intelligent Information Security Engineering**
**Faculty of Artificial Intelligence Engineering — Syrian Private University**
**Academic Year 2025 – 2026**

---

## Overview

This project designs, implements, and evaluates a complete Zero Trust security architecture for a Software-Defined Network. The whole system runs as Docker containers on a single Windows laptop with WSL2 — no virtual machines required.

Eight cooperating services are integrated:

| Service | Role | Port |
|---------|------|------|
| **ONOS 2.7** | SDN controller (Policy Enforcement Point) | 6653, 8181, 8101 |
| **HashiCorp Vault 1.15** | PKI / Certificate Authority | 8200 |
| **Keycloak 22** | Identity Provider (OIDC, JWT) | 8080 |
| **Open Policy Agent 0.58** | Policy Decision Point (Rego) | 8282 |
| **Elasticsearch 8.11** | Centralized log storage | 9200 |
| **Logstash 8.11** | Log ingestion & processing | 5044, 5514 |
| **Kibana 8.11** | Dashboards & visualization | 5601 |
| **Mininet 2.3** | 4-zone emulated data plane (in WSL2) | — |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                Windows Laptop / Docker Desktop               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │       Docker Bridge Network — 172.20.0.0/16            │  │
│  │                                                        │  │
│  │   ONOS 2.7  Vault 1.15  Keycloak 22  OPA 0.58          │  │
│  │      ↕         ↕            ↕          ↕               │  │
│  │   Logstash ←─ Elasticsearch ←─ Kibana                  │  │
│  └────────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌─────────────────────────│────────────────────────────┐    │
│  │  WSL2 (Ubuntu 22.04)    ↓                            │    │
│  │  Mininet → s100 (core)                               │    │
│  │             ├── s1 (DMZ        10.0.1.0/24)          │    │
│  │             ├── s2 (Internal   10.0.2.0/24)          │    │
│  │             ├── s3 (Restricted 10.0.3.0/24)          │    │
│  │             └── s4 (IoT        10.0.4.0/24)          │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

**Network zones:** DMZ, Internal, Restricted, IoT — 11 hosts in total.

---

## Repository Layout

```
zero-trust-sdn/
├── README.md                              ← this file
├── docs/
│   └── Zero_Trust_SDN_Graduation_Report.docx   ← full report (88 pages)
├── deployment/
│   ├── docker-compose.yml                 ← all 7 services
│   ├── opa/
│   │   ├── policies/zero_trust.rego       ← Rego policy (default-deny)
│   │   └── data/network_zones.json        ← zone definitions
│   ├── elk/logstash/
│   │   ├── config/logstash.yml
│   │   └── pipeline/zero-trust.conf       ← log ingestion pipeline
│   ├── mininet/topology/
│   │   └── zt_topology.py                 ← 5 switches + 11 hosts
│   └── scripts/
│       ├── setup_vault_pki.sh             ← bootstrap Vault PKI
│       ├── setup_keycloak.sh              ← bootstrap Keycloak realm
│       └── health_check.sh                ← service health probe
└── tests/
    ├── test_opa_policy.sh                 ← OPA policy validation
    ├── pentest_01_bruteforce.sh           ← Brute-force on Keycloak
    ├── pentest_02_unauth_api.sh           ← Unauthorized ONOS API
    ├── pentest_03_policy_bypass.sh        ← OPA policy bypass
    ├── pentest_04_token_replay.sh         ← JWT theft & replay
    ├── pentest_05_log_injection.sh        ← Log injection on ELK
    └── pentest_06_cross_zone.sh           ← Cross-zone traffic test
```

---

## Prerequisites

You need a Windows 10/11 laptop with **at least 16 GB RAM** and:

1. **WSL2** with Ubuntu 22.04
2. **Docker Desktop** with the WSL2 backend enabled
3. **Mininet + Open vSwitch** inside WSL2

### Quick install (run inside an Administrator PowerShell):

```powershell
wsl --install
# reboot, then create username + password in Ubuntu
```

### Inside Ubuntu (WSL2):

```bash
# System tools
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget jq git net-tools \
    python3 python3-pip openjdk-11-jdk maven \
    mininet openvswitch-switch openvswitch-common nmap

# Python helpers
sudo pip3 install requests flask --break-system-packages
```

### WSL2 resource configuration

Create `C:\Users\<your-name>\.wslconfig`:

```ini
[wsl2]
memory=10GB
processors=4
swap=2GB
```

Then run `wsl --shutdown` in PowerShell to apply.

---

## Quick Start

```bash
# 1. Clone the repo (in WSL2)
git clone https://github.com/<your-username>/zero-trust-sdn.git
cd zero-trust-sdn/deployment

# 2. Pull all images (5–10 min on first run)
docker-compose pull

# 3. Start every service in the background
docker-compose up -d

# 4. Wait until every container is healthy (~3 min)
watch docker-compose ps

# 5. Bootstrap Vault PKI
chmod +x scripts/*.sh
./scripts/setup_vault_pki.sh

# 6. Bootstrap Keycloak realm + roles + test user
./scripts/setup_keycloak.sh

# 7. Verify everything
./scripts/health_check.sh

# 8. (Separate terminal) Start the Mininet topology
sudo service openvswitch-switch start
sudo python3 mininet/topology/zt_topology.py
```

---

## Web Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| ONOS GUI | http://localhost:8181/onos/ui | `karaf` / `karaf` |
| Vault UI | http://localhost:8200/ui | Token: `zt-root-token-2024` |
| Keycloak | http://localhost:8080 | `admin` / `ZtK3ycl0ak!2024` |
| Kibana | http://localhost:5601 | (no auth) |

**⚠️ These are LAB credentials — change them before any real deployment. See Chapter 6 of the report for production hardening.**

---

## Running the Tests

### Functional tests

```bash
cd tests
chmod +x *.sh

# Test the Zero Trust Rego policy (10 cases, all should PASS)
./test_opa_policy.sh
```

### Penetration tests

```bash
# 1. Brute force on Keycloak (lockout should activate at attempt 6)
./pentest_01_bruteforce.sh

# 2. Unauthorized ONOS API access (with default credentials)
./pentest_02_unauth_api.sh

# 3. OPA policy bypass (role injection + malicious policy upload)
./pentest_03_policy_bypass.sh

# 4. JWT token theft & replay
./pentest_04_token_replay.sh

# 5. Log injection on Elasticsearch
./pentest_05_log_injection.sh

# 6. Cross-zone traffic test (run with Mininet active)
./pentest_06_cross_zone.sh
```

---

## Vulnerability Assessment Results

The full VA based on **NIST SP 800-115** identified **12 vulnerabilities**:

| Severity | Count | Examples |
|----------|-------|----------|
| **CRITICAL** | 2 | Vault dev mode + static token, no TLS |
| **HIGH**     | 5 | Default credentials, no auth on OPA / Elasticsearch |
| **MEDIUM**   | 3 | Kibana no auth, flat network, exposed SSH |
| **LOW**      | 2 | Long CA TTLs, no log input validation |

Every vulnerability has a corresponding countermeasure documented in **Chapter 6** of the report.

## Penetration Testing Results

| # | Test | Defense Effective? |
|---|------|--------------------|
| PT-01 | Brute-force on Keycloak | ✅ YES (account locked at attempt 6) |
| PT-02 | Unauthorized ONOS API | ❌ NO (default creds) → ✅ after fix |
| PT-03 | OPA policy bypass | ⚠️ PARTIAL → ✅ after nginx + JWT |
| PT-04 | JWT theft & replay | ⚠️ PARTIAL (5-min TTL helps) |
| PT-05 | Log injection on ELK | ❌ NO → ✅ after `xpack.security` |
| PT-06 | Cross-zone traffic | ✅ YES (when deny rules installed) |

---

## Documentation

The complete graduation report (88 pages, 7 chapters, 47 tables, 19 figures) is in [`docs/Zero_Trust_SDN_Graduation_Report.docx`](docs/Zero_Trust_SDN_Graduation_Report.docx).

**Chapters:**

1. **Theoretical Framework** — SDN, OpenFlow, Docker, Zero Trust, Keycloak, Vault, OPA, ELK
2. **Related Works** — comparative analysis of 7 prior studies
3. **Proposed System Architecture** — design principles, components, zoning
4. **Practical Implementation** — every command and config explained line by line
5. **Vulnerability Assessment** — 6-step NIST 800-115 methodology, 12 findings
6. **Countermeasures** — defense-in-depth, fix per vulnerability
7. **Penetration Testing** — 6 active attacks, PTES methodology

---

## Stopping the System

```bash
# Stop all containers (keep volumes)
docker-compose down

# Stop and remove all data (start fresh next time)
docker-compose down -v

# Exit Mininet:
mininet> exit
sudo mn -c   # cleanup leftover virtual interfaces
```

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

The project is intended for **educational and research purposes** only. The credentials and configurations included are deliberately weakened for clarity and **must not be used in any production environment** without applying the countermeasures from Chapter 6.

---

## Acknowledgements

- **Dr. Christine Zeineh** — Head of the Department of Intelligent Information Security Engineering
- **Dr. Muhayb Al-Naqari** — Dean of the Faculty of Artificial Intelligence Engineering
- The faculty members of the Syrian Private University

---

## Contact

For questions or contributions, please open an issue on this repository.
