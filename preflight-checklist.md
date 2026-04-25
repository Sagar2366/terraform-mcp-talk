# Pre-Flight Checklist — Demo Machine Setup

Run through this the night before or morning of. Takes ~20 min.

---

## 1. Install Kiro

### Option A: Kiro Desktop (recommended for demo)

Download from https://kiro.dev/downloads

After install:
- Open Kiro
- Sign in with your AWS account
- Verify it works: type a message like "Hello"

### Option B: Kiro CLI (for terminal-based demo)

```bash
# Check install docs at https://kiro.dev/docs/cli/getting-started
# Install method may vary — verify before demo

# Verify:
kiro-cli --version
```

### Which to use for the demo?

- **Kiro Desktop** — better for showing generated files side by side (editor + chat panel)
- **Kiro CLI in terminal** — better for "pure terminal" look, easier for audience to follow

Pick one and stick with it. Don't switch mid-demo.

---

## 2. Software Versions

```bash
terraform version        # Need >= 1.6 (ideally 1.9+) for terraform test
node --version           # Need v18+ for npx (skills install)
git --version            # Need for cloning Anton's skill
docker --version         # Need for Docker-based MCP server
kiro-cli --version       # Verify Kiro CLI is installed
```

---

## 3. AWS Account Setup

**You will create REAL AWS resources during the demo. Set this up carefully.**

```bash
# Option A: Environment variables (recommended for demo — no files to leak)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

# Option B: AWS CLI profile
aws configure --profile demo
export AWS_PROFILE=demo

# Verify access:
aws sts get-caller-identity
```

**Security checklist:**
- [ ] Use a dedicated demo AWS account or sandbox — NOT your production account
- [ ] Set a billing alert ($10 threshold)
- [ ] Use an IAM user with only EC2/VPC/SG permissions — not admin
- [ ] NEVER hardcode keys in `.tf` files — always use env vars or profiles
- [ ] Have `terraform destroy` ready to run immediately after each Act

**Estimated cost:** ~$0.02 for a t3.micro running 30 min. Destroy promptly.

---

## 4. Set Up the Terraform MCP Server (Docker)

**IMPORTANT:** Verify this image exists before relying on it. Run the pull
command during dry-run.

```bash
# Pull the image ahead of time:
docker pull hashicorp/terraform-mcp-server:latest
```

MCP config (`.kiro/settings/mcp.json`):

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "hashicorp/terraform-mcp-server"
      ],
      "env": {}
    }
  }
}
```

### Kiro MCP config location

- **Project-level** (recommended for demo): `<project-dir>/.kiro/settings/mcp.json`
- **User-level**: `~/.kiro/settings/mcp.json`
- **CLI command**: `kiro-cli mcp add --name "terraform" --command "docker" --args "run -i --rm hashicorp/terraform-mcp-server"`

---

## 5. Create Demo Directories

```bash
# Naive dir — clean, no config
mkdir -p ~/demo-terraform-naive/

# Full dir — with MCP config
mkdir -p ~/demo-terraform-full/.kiro/settings/

# Write the MCP config
cat > ~/demo-terraform-full/.kiro/settings/mcp.json << 'EOF'
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "hashicorp/terraform-mcp-server"
      ],
      "env": {}
    }
  }
}
EOF
```

---

## 6. Pre-Clone Anton's Skill (backup)

You install this live in Act 2, but pre-clone so you have a fallback if GitHub is slow:

```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/terraform-skill-backup
```

During the demo (Act 2) — use npx skills (IDE-agnostic):
```bash
npx skills add antonbabenko/terraform-skill
```

If that's slow live, manually copy:
```bash
# Verify the correct target directory during dry-run
cp -r ~/terraform-skill-backup <kiro-skills-directory>/terraform
```

**NOTE:** Verify where Kiro expects skill files during dry-run.
Try `npx skills add` first — it handles the path automatically.

---

## 7. Skills Installation Strategy

Skills are installed LIVE to show incremental improvement:

| Act   | Skills state                    | How                                          |
|-------|---------------------------------|----------------------------------------------|
| Act 1 | NO skills, NO MCP              | `~/demo-terraform-naive/`, no config         |
| Act 2 | Install Anton's + HashiCorp    | `npx skills add` for both                    |
| Act 3 | Both skills + MCP active       | Same dir, everything loaded                  |
| Act 4 | Same — now add tests           | `terraform test` on generated code           |

**Before Act 1, make sure no skills are loaded.**
Verify during dry-run how to remove/disable skills in Kiro.

---

## 8. Dry Run Each Act

### Test Act 1 (naive):
```bash
cd ~/demo-terraform-naive/
kiro-cli   # or open in Kiro Desktop
# Paste the naive prompt from prompts.md
# Verify: output is basic single-file, insecure
terraform init && terraform plan
# If plan looks right: terraform apply -auto-approve
# IMMEDIATELY after reviewing: terraform destroy -auto-approve
```

### Test Act 2 (install skills):
```bash
npx skills add antonbabenko/terraform-skill
npx skills add hashicorp/agent-skills
cd ~/demo-terraform-full/
kiro-cli   # or open in Kiro Desktop
# Verify: MCP tools show up (use /mcp or ask Kiro to list tools)
# Verify: skills are loaded
```

### Test Act 3 (same vague prompt + constraints):
```bash
# Paste the Act 3 prompt from prompts.md
# Verify: output is multi-file, encrypted, tagged, HTTPS-only, no hardcoded secrets
terraform init && terraform plan
# If plan looks right: terraform apply -auto-approve
# IMMEDIATELY after reviewing: terraform destroy -auto-approve
```

### Test Act 4 (terraform test):
```bash
# Paste the "write tests" prompt from prompts.md
terraform init
terraform test -filter=tests/ec2.tftest.hcl
# Verify: tests run (pass or fail is fine — both are demo-able)
```

**After dry run, clean up EVERYTHING:**
```bash
# Destroy any real AWS resources
cd ~/demo-terraform-naive && terraform destroy -auto-approve 2>/dev/null
cd ~/demo-terraform-full && terraform destroy -auto-approve 2>/dev/null

# Remove skills (verify command during dry-run)
# npx skills remove antonbabenko/terraform-skill
# npx skills remove hashicorp/agent-skills

# Clean generated files
rm -rf ~/demo-terraform-naive/*.tf ~/demo-terraform-naive/.terraform
rm -rf ~/demo-terraform-full/*.tf ~/demo-terraform-full/tests/ ~/demo-terraform-full/.terraform
```

---

## 9. Kiro Desktop Layout for Demo

```
┌─────────────────────────────┬────────────────────────┐
│                             │                        │
│    Editor pane              │    Kiro chat panel      │
│    (shows generated .tf)    │    (prompts + output)   │
│                             │                        │
│                             │                        │
└─────────────────────────────┴────────────────────────┘
```

- Open Kiro with the demo directory
- Chat panel on the right
- Editor on the left — files appear as Kiro creates them
- Terminal at the bottom for `terraform init` / `terraform apply` / `terraform test`
- Font size: increase for audience visibility

---

## 10. Fallback Plans

**If MCP server doesn't connect:**
- Restart Docker and re-pull: `docker pull hashicorp/terraform-mcp-server:latest`
- If Docker fails entirely: explain MCP verbally, focus on skills + terraform test
- The test-driven loop works without MCP

**If Docker image doesn't exist:**
- Check https://github.com/hashicorp/terraform-mcp-server for updated image name
- Worst case: explain MCP conceptually, skip live MCP demo

**If skills install fails live:**
- `cp -r ~/terraform-skill-backup <target-dir>/terraform` (pre-cloned)
- For HashiCorp: `npx skills add hashicorp/agent-skills`
- Worst case: skip to Act 3/4, explain skills conceptually

**If terraform test fails on weird attribute paths:**
- That's actually good for the demo — show the fix loop
- If it keeps failing: `terraform validate` as simpler alternative

**If AWS credentials don't work:**
- Verify: `aws sts get-caller-identity`
- Fall back to `terraform plan` only (no apply) — still shows the code differences
- `terraform test` with `mock_provider` works without any AWS credentials

---

## 11. Time Checkpoints

| Time  | Act     | What's happening                                       |
|-------|---------|-------------------------------------------------------|
| 0:00  | Opening | Problem statement — on camera, no terminal             |
| 2:00  | Act 1   | Naive prompt, show insecure output, apply + review     |
| 8:00  | Act 2   | Install MCP + skills, verify they loaded               |
| 18:00 | Act 3   | Same intent + constraints, apply + compare with naive  |
| 28:00 | Act 4   | Write tests, run them, fix failures, rerun             |
| 40:00 | Close   | Three-point recap, destroy all resources, links        |

---

## 12. Quick Recovery

```bash
# Kiro hangs:
# Ctrl+C, restart: kiro-cli (or reopen Kiro Desktop)

# terraform test errors on init:
rm -rf .terraform .terraform.lock.hcl && terraform init

# Docker MCP server errors:
docker pull hashicorp/terraform-mcp-server:latest

# AWS auth errors:
aws sts get-caller-identity
# If it fails, re-export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

# Nuclear reset:
cd ~/demo-terraform-naive && terraform destroy -auto-approve 2>/dev/null
cd ~/demo-terraform-full && terraform destroy -auto-approve 2>/dev/null
rm -rf ~/demo-terraform-naive/*.tf ~/demo-terraform-full/*.tf
rm -rf ~/demo-terraform-full/tests/
```

---

## 13. Post-Demo Checklist

**DO NOT FORGET — destroy all AWS resources after the demo:**

```bash
cd ~/demo-terraform-naive && terraform destroy -auto-approve
cd ~/demo-terraform-full && terraform destroy -auto-approve
```

Verify in AWS console that no resources remain:
- EC2 instances terminated
- Security groups deleted (except default)
- VPCs deleted (except default)
- No running costs
