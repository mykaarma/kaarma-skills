---
name: vuln-scan
description: >
  Run vulnerability scans during local development to find critical and high-severity issues before they reach production.
  Use this skill whenever the user asks to: scan for vulnerabilities, audit dependencies, check for CVEs, find security issues in their code or containers, scan a Docker image, check Kubernetes manifests for security misconfigurations, look for hardcoded secrets or leaked credentials, or run any kind of security check on their project.
  Also trigger when the user says things like "is this safe to deploy?", "check my dependencies", "any security issues?", or "run a security scan".
  Covers: Node.js/npm, Python/pip, Go, Java/Maven, Docker images, Kubernetes manifests, and secrets detection.
---

# Vulnerability Scanner for Local Development

Scan projects for critical/high-severity vulnerabilities across dependencies, containers, Kubernetes configs, and secrets — and surface actionable fixes.

---

## Step 1: Auto-detect Project Type

Before running anything, identify what you're working with:

```bash
# Run from the project root. Check for these indicators:
ls package.json package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null  # Node.js
ls requirements.txt Pipfile pyproject.toml setup.py 2>/dev/null           # Python
ls go.mod go.sum 2>/dev/null                                               # Go
ls pom.xml build.gradle 2>/dev/null                                        # Java
ls Dockerfile docker-compose.yml 2>/dev/null                               # Docker
find . -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind:" 2>/dev/null # K8s manifests
ls .git 2>/dev/null && git log --oneline -1 2>/dev/null                    # Git repo (for secrets)
```

Announce what you detected: *"Found: Node.js project + Dockerfile + Kubernetes manifests. Running scans for all three."*

---

## Step 2: Run Scanners by Type

### Node.js / npm
```bash
# Built-in, no install needed
npm audit --audit-level=critical 2>/dev/null || npm audit

# For yarn projects:
yarn audit --level critical 2>/dev/null

# For pnpm:
pnpm audit --audit-level critical 2>/dev/null
```

### Python
```bash
# Install pip-audit if needed
pip install pip-audit --quiet 2>/dev/null || pip3 install pip-audit --quiet

# Scan current environment or requirements file
pip-audit --requirement requirements.txt --severity critical 2>/dev/null \
  || pip-audit --severity high 2>/dev/null \
  || pip-audit
```

### Go
```bash
# Install govulncheck if not present
go install golang.org/x/vuln/cmd/govulncheck@latest 2>/dev/null
govulncheck ./...
```

### Java / Maven
```bash
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7 2>/dev/null
# Or with Gradle:
./gradlew dependencyCheckAnalyze 2>/dev/null
```

### Docker Images
```bash
# Install trivy if not present (macOS)
brew install trivy 2>/dev/null || \
  (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null)

# Scan image - replace IMAGE_NAME with actual image
trivy image --severity CRITICAL,HIGH --exit-code 0 IMAGE_NAME

# Scan Dockerfile for misconfigs
trivy config --severity CRITICAL,HIGH Dockerfile 2>/dev/null
```

### Kubernetes Manifests
```bash
# Trivy can scan K8s manifests too
trivy config --severity CRITICAL,HIGH ./k8s/ 2>/dev/null
trivy config --severity CRITICAL,HIGH . --include-non-failures 2>/dev/null

# Also check with kubesec if available
kubesec scan ./k8s/*.yaml 2>/dev/null
```

### Secrets Detection (always run this)
```bash
# Install gitleaks if not present
if ! command -v gitleaks &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install gitleaks 2>/dev/null
  elif command -v apt-get &>/dev/null; then
    echo "Install gitleaks manually: https://github.com/gitleaks/gitleaks/releases"
  else
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
      x86_64)  ARCH="x64" ;;
      aarch64|arm64) ARCH="arm64" ;;
    esac
    LATEST=$(curl -sSf https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/${LATEST}/gitleaks_${LATEST#v}_${OS}_${ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin 2>/dev/null \
      || echo "Could not install gitleaks automatically. Visit: https://github.com/gitleaks/gitleaks/releases"
  fi
fi

# Scan git history and working directory
gitleaks detect --source . --report-format json --report-path /tmp/gitleaks-report.json 2>/dev/null
gitleaks detect --source . 2>/dev/null || echo "Run: brew install gitleaks"

# Fallback: grep for common patterns
grep -rn \
  -e "password\s*=\s*['\"][^'\"]\+" \
  -e "api[_-]key\s*=\s*['\"][^'\"]\+" \
  -e "secret\s*=\s*['\"][^'\"]\+" \
  -e "AWS_SECRET_ACCESS_KEY" \
  -e "PRIVATE KEY" \
  --include="*.py" --include="*.js" --include="*.ts" --include="*.go" \
  --include="*.yaml" --include="*.yml" --include="*.env" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  . 2>/dev/null \
  | grep -v "_test\." \
  | grep -v "example\|sample\|placeholder" \
  | awk -F: '{print $1 ":" $2 ": [potential secret — value redacted]"}' \
  | head -30
```

---

## Step 3: Parse and Filter Results

Focus ONLY on **CRITICAL** and **HIGH** severity. Suppress INFO/LOW/MEDIUM unless user asks.

For each finding, extract:
- **CVE ID** (e.g., CVE-2023-12345)
- **Package name + affected version**
- **Severity** (CRITICAL / HIGH)
- **CVSS score** if available
- **Fix version** (what to upgrade to)
- **Brief description** (what the vuln does — RCE, SSRF, SQLi, etc.)

---

## Step 4: Present Results

Format output as a prioritized table, then remediation commands:

```
## 🔴 Vulnerability Scan Results

**Scanned**: <project type(s)>  
**Total findings**: X critical, Y high  
**Scan time**: <timestamp>

---

### CRITICAL Vulnerabilities

| # | Package | CVE | CVSS | Description | Fix |
|---|---------|-----|------|-------------|-----|
| 1 | lodash@4.17.20 | CVE-2021-23337 | 7.2 | Command injection via template | 4.17.21 |
| 2 | ... | | | | |

### HIGH Vulnerabilities

| # | Package | CVE | CVSS | Description | Fix |
|---|---------|-----|------|-------------|-----|
...

---

### 🔧 Remediation Commands

# Fix all at once (Node.js):
npm audit fix

# Or upgrade specific packages:
npm install lodash@4.17.21

# Packages requiring manual review (breaking changes):
npm audit fix --force  # ⚠️ May introduce breaking changes — review changelog first
```

If **no critical/high vulns found**:
```
✅ No CRITICAL or HIGH vulnerabilities found.
   (X low/medium findings suppressed — run with --all to see them)
```

---

## Step 5: Contextual Advice

After the table, add a brief section:

**If secrets were found**: Immediately flag this as highest priority. Advise rotating the credential NOW, check git history with `git log -S "secret_value"`, add to `.gitignore`.

**If K8s misconfigs found**: Common ones to call out:
- `runAsRoot: true` → add `securityContext.runAsNonRoot: true`
- Missing resource limits → add `resources.limits.cpu/memory`
- `privileged: true` → remove unless absolutely necessary
- Missing network policies

**If Docker vulns found**: Suggest base image upgrades (`FROM node:20-alpine` instead of older/larger images).

**For dependency vulns with no fix available**: Note workarounds (e.g., disable the vulnerable code path, use a fork, pin to a safe version).

---

## Handling Missing Tools

If a scanner isn't installed and can't be installed automatically, don't fail silently. Tell the user:

```
⚠️  trivy not found. To scan Docker images and K8s manifests:
    brew install trivy        # macOS
    # or: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
```

Then continue with the scanners that ARE available.

---

## Reference: Severity Thresholds

| Severity | CVSS Score | Action |
|----------|------------|--------|
| CRITICAL | 9.0–10.0 | Fix immediately before any deployment |
| HIGH | 7.0–8.9 | Fix in current sprint / before next release |
| MEDIUM | 4.0–6.9 | Track and fix within 30 days |
| LOW | 0.1–3.9 | Fix opportunistically |

---

## Reference: Common False Positives to Note

- Dev-only dependencies (`devDependencies` in package.json) that don't ship to production — flag but mark as lower priority
- Vulns in test frameworks (jest, pytest) — flag but note they're test-only
- Vulns requiring local file system access on a server-side-only package — mention but context-matters

---

## Quick Mode

If the user just wants a fast check (e.g., "quick vuln scan"), run only:
1. The language-specific dependency scan (npm audit / pip-audit / govulncheck)
2. The secrets grep fallback

Skip container and K8s scans unless Dockerfile/manifests are explicitly mentioned.
