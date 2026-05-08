# How to Upload This Project to GitHub

This guide walks you through publishing the Zero Trust SDN project on GitHub.

---

## Option 1 — Using the GitHub Web Interface (easiest, no Git knowledge needed)

### Step 1 — Create a new repository

1. Go to https://github.com and log in (or create a free account).
2. In the top-right corner, click the **`+`** icon → **New repository**.
3. Fill in:
   - **Repository name**: `zero-trust-sdn` (or anything you like)
   - **Description**: `Zero Trust Architecture for SDN — Graduation Project 2`
   - **Public** or **Private** — your choice (pick Public if you want it visible on your CV)
   - **Do NOT** check "Initialize with a README" — we already have one
4. Click **Create repository**.

### Step 2 — Upload the files

1. On the empty repo page, click **uploading an existing file** (it's a link in the page text).
2. Drag and drop the entire `zero-trust-sdn-repo` folder contents (or zip and drag the zip).
3. Scroll down, write a commit message like `Initial commit: Zero Trust SDN project`.
4. Click **Commit changes**.

Done! Share the URL: `https://github.com/<your-username>/zero-trust-sdn`

---

## Option 2 — Using Git (more professional)

### Step 1 — Create the repo on GitHub (same as Step 1 above, but skip the upload step)

### Step 2 — Install Git inside WSL2

```bash
sudo apt install -y git
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

### Step 3 — Initialize and push

```bash
# Move to the project folder
cd ~/zero-trust-sdn-repo  # or wherever you extracted the zip

# Initialize Git
git init
git add .
git commit -m "Initial commit: Zero Trust SDN project"

# Connect to your GitHub repo (replace <your-username>!)
git branch -M main
git remote add origin https://github.com/<your-username>/zero-trust-sdn.git

# Push (you'll be asked for username + a Personal Access Token)
git push -u origin main
```

> **About the password:** GitHub no longer accepts your account password for git push. You need a **Personal Access Token (PAT)**:
> 1. Go to https://github.com/settings/tokens
> 2. Click **Generate new token (classic)**
> 3. Give it a name, set an expiration, and check the **`repo`** scope
> 4. Copy the token — paste it when git asks for the password

---

## Option 3 — Using GitHub Desktop (graphical, easiest after the first push)

1. Download GitHub Desktop from https://desktop.github.com
2. Sign in with your GitHub account
3. **File** → **Add local repository** → choose your `zero-trust-sdn-repo` folder
4. It will say "this is not a Git repository" — click **create a repository**
5. Click **Publish repository** at the top
6. Pick a name and click **Publish**

---

## What Will Be On GitHub

After upload, your repo will look like this:

```
zero-trust-sdn/
├── README.md                              ← shown on the GitHub repo home page
├── LICENSE
├── .gitignore
├── docs/
│   └── Zero_Trust_SDN_Graduation_Report.docx
├── deployment/
│   ├── docker-compose.yml
│   ├── opa/
│   │   ├── policies/zero_trust.rego
│   │   └── data/network_zones.json
│   ├── elk/logstash/
│   │   ├── config/logstash.yml
│   │   └── pipeline/zero-trust.conf
│   ├── mininet/topology/zt_topology.py
│   └── scripts/
│       ├── setup_vault_pki.sh
│       ├── setup_keycloak.sh
│       └── health_check.sh
└── tests/
    ├── test_opa_policy.sh
    ├── pentest_01_bruteforce.sh
    ├── pentest_02_unauth_api.sh
    ├── pentest_03_policy_bypass.sh
    ├── pentest_04_token_replay.sh
    ├── pentest_05_log_injection.sh
    └── pentest_06_cross_zone.sh
```

---

## Polish Tips (after the first push)

These are optional but make your repo look professional:

- **Add topics**: on your repo page, click the gear icon next to "About" and add: `zero-trust`, `sdn`, `docker`, `network-security`, `graduation-project`, `onos`, `keycloak`, `vault`, `opa`, `elk-stack`, `mininet`, `penetration-testing`
- **Pin the repo**: from your GitHub profile → **Customize your pins** → tick the repo
- **Add a description**: short one-liner, e.g. `Docker-based Zero Trust SDN with VA, Countermeasures and Pen-Testing`
- **Add screenshots**: take 2–3 screenshots of Kibana / ONOS GUI, drop them in a `docs/screenshots/` folder, then reference them in the README with `![alt](docs/screenshots/file.png)`

---

## Sharing the Link

Once published, anyone can read your project at:

```
https://github.com/<your-username>/zero-trust-sdn
```

Add this URL to your CV, LinkedIn, and to the front cover of the report if you wish.

---

## Need Help?

If you get stuck on any step, just send me a screenshot of the error — I can help debug.
