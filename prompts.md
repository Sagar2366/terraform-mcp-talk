# Demo Prompts — Copy-Paste Ready

Keep this open in a second tab. Copy-paste each prompt when its moment comes.

Everything in this repo — Terraform configs, tests, `.gitignore` — is generated LIVE from these prompts using Kiro.

---

## 0. Pre-Demo Setup

### Local machine

```bash
terraform version    # >= 1.6 (>= 1.7 if you want mocks)
node --version       # >= 18 for npx
docker --version     # For MCP server
kiro-cli --version   # Or Kiro Desktop from kiro.dev/downloads
```

No AWS credentials needed for the core demo — everything runs with `terraform plan` + `mock_provider`.

### AWS (optional, if you want to show `apply`)

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

Use a dedicated demo AWS account with minimal EC2/VPC/SG permissions. Not production.

### Demo directories

```bash
# Naive dir — no MCP config, no skills
mkdir -p ~/demo-terraform-naive/

# Full dir — with MCP config for Kiro
mkdir -p ~/demo-terraform-full/.kiro/settings/

cat > ~/demo-terraform-full/.kiro/settings/mcp.json << 'EOF'
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"],
      "env": {}
    }
  }
}
EOF

# Pull MCP server Docker image ahead of time
docker pull hashicorp/terraform-mcp-server:latest
```

---

## Act 1 — Naive Baseline (no MCP, no skills)

**Dir:** `~/demo-terraform-naive/`
**Tools:** none

Start Kiro in this directory and paste:

```text
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

Let it generate whatever it thinks is "simple".

From a shell:

```bash
cd ~/demo-terraform-naive
terraform init
terraform plan
```

On screen, point out likely issues:

- 0.0.0.0/0 on SSH/HTTP,
- no encryption,
- no tags,
- hardcoded AMI,
- single `main.tf`, local state.

You don't need to apply in the live demo.

---

## Act 2 — Install Skills + Verify MCP

**Dir:** `~/demo-terraform-full/`
**Tools:** skills being installed, MCP active via Docker

### 2.1 Install skills

From a shell (anywhere):

```bash
npx -y skills add antonbabenko/terraform-skill
npx -y skills add hashicorp/agent-skills
```

### 2.2 Verify MCP and skills in Kiro

In Kiro, started from `~/demo-terraform-full/`:

```text
List the Terraform-related tools you have access to right now
and describe each in one short line.
```

Then:

```text
What skills do you have loaded? Summarize each in one line.
```

Keep this section short — just prove they're loaded, then move on.

---

## Act 3 — Same Prompt + Constraints (MCP + Skills)

**Dir:** `~/demo-terraform-full/`
**Tools:** MCP + Anton's skill + HashiCorp Agent Skills

Same opening line as Act 1 — the constraints do the work.

Paste into Kiro:

```text
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
Put all generated Terraform files in an infra/ directory.
Use a local backend — no remote state.

Constraints:
- No hardcoded credentials, API keys, or secrets anywhere.
- No inline security group rules — use aws_vpc_security_group_ingress_rule
  and aws_vpc_security_group_egress_rule resources.
- Use variables for region, instance type, and any value that might change.
- All resources must have tags: Name, ManagedBy=terraform, Environment, Team.
- The EC2 root volume must be encrypted.
- The security group must allow ONLY HTTPS (443) inbound from 0.0.0.0/0.
  Do NOT allow SSH, HTTP, or any other port from 0.0.0.0/0.
- Use the AWS provider's default_tags block for common tags.
- Generate separate files: main.tf, variables.tf, outputs.tf.
- Use a data source for AMI lookup instead of hardcoding AMI IDs.

If you cannot satisfy any constraint, say so explicitly and explain which one.
```

Let Kiro generate the files under `~/demo-terraform-full/infra/`.

From a shell:

```bash
cd ~/demo-terraform-full/infra
cat main.tf
cat variables.tf
cat outputs.tf

terraform init
terraform plan
```

On screen, compare to Act 1:

- No SSH from 0.0.0.0/0 — only 443 open.
- Encrypted root volume.
- Tags present.
- Multiple files, variables instead of hard-coded values.
- Data source for AMI.

Same intent, very different result.

---

## Act 4 — Write Tests, Run Them, Fix Failures

**Goal:** show `terraform test` as the contract that catches anything the AI misses.

### 4.1 Ask Kiro to write the tests

In Kiro (still in `~/demo-terraform-full`):

```text
Write a Terraform test file at infra/tests/ec2.tftest.hcl that enforces
these rules for the current configuration in infra/:

1. The EC2 instance type must be t3.micro.
2. The root volume must be encrypted.
3. The security group must allow only HTTPS (443) from 0.0.0.0/0
   and no other ingress from 0.0.0.0/0.
4. All resources must have tags: ManagedBy, Environment, and Team.

Use mock_provider "aws" so tests run without AWS credentials.
Use a single run block with command = "plan" and clear assertions.
Do not change my existing *.tf files, just output the test file content.
```

Create the mock provider file:

```bash
mkdir -p ~/demo-terraform-full/infra/tests/mocks
cat > ~/demo-terraform-full/infra/tests/mocks/aws.tfmock.hcl << 'EOF'
mock_provider "aws" {}
EOF
```

### 4.2 Run tests

```bash
cd ~/demo-terraform-full/infra
terraform init
terraform test -filter=tests/ec2.tftest.hcl
```

If tests fail due to attribute paths, that's good demo material.

In Kiro, paste:

```text
terraform test -filter=tests/ec2.tftest.hcl failed with this error:

[PASTE THE ERROR OUTPUT HERE]

Update infra/tests/ec2.tftest.hcl so that all assertions reference
real attributes from the current configuration. Do not weaken the rules.
Do not modify my *.tf files.
```

Update the file, then rerun:

```bash
terraform test -filter=tests/ec2.tftest.hcl
```

Now you can say: "The AI had to satisfy the tests, not the other way around."

---

## Cleanup

```bash
# Just remove generated files — no AWS resources were created
rm -rf ~/demo-terraform-naive/*.tf ~/demo-terraform-naive/.terraform
rm -rf ~/demo-terraform-full/infra/ ~/demo-terraform-full/.terraform
```

If you applied anything for real:

```bash
cd ~/demo-terraform-full/infra && terraform destroy -auto-approve || true
cd ~/demo-terraform-naive && terraform destroy -auto-approve || true
```

---

## Optional — Constraint Prompt (Standalone SG)

If you have time and want to show a strongly constrained prompt:

```text
Generate ONLY an aws_security_group resource that:

- Belongs to variable vpc_id
- Allows ingress HTTPS (443) from 0.0.0.0/0
- Does NOT allow any other ingress from 0.0.0.0/0 on any port
- Has a description on every rule
- Has tags Name, ManagedBy, Environment, Team
- Does NOT contain any hardcoded credentials or secrets

If you cannot satisfy one of these constraints, say so explicitly
and explain which one.
```

---

## Optional — Refactor Naive Config

```text
Here is a naive single-file Terraform config for VPC + subnet + EC2:

[PASTE ~/demo-terraform-naive/main.tf HERE]

Refactor this into a production-ready layout:

- main.tf, variables.tf, outputs.tf in an infra/ directory
- Proper variable definitions (no hardcoded region/AMI/instance_type)
- Tags: ManagedBy, Environment, Team everywhere
- HTTPS-only security group, encrypted root volume
- No hardcoded credentials, API keys, or secrets
- Use data source for AMI lookup

Keep behavior equivalent where safe, and explain the main improvements.
```

---

## Optional — Act 5: CI/CD Pipeline (GitHub Actions)

Only do this if you have time and a repo wired up with secrets.

In Kiro:

```text
Generate a GitHub Actions workflow at .github/workflows/deploy.yml for this
Terraform project in the current repository.

Requirements:
- Run on push to main, pull_request to main, workflow_dispatch.
- Use env variables:
  - TF_VERSION = "1.12.0"
  - TF_WORKING_DIR = infra

- Jobs:
  1. terraform-validate:
     - Checkout code
     - Install Terraform via curl (no setup-terraform action)
     - Run: terraform fmt -check
     - Run: terraform init
     - Run: terraform validate
     - Run: terraform test if any .tftest.hcl files exist (skip gracefully if none).

  2. terraform-apply:
     - Needs: terraform-validate
     - environment: production
     - Use AWS credentials from GitHub Secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
     - Install Terraform via curl
     - Run: terraform init
     - Run: terraform plan -out=tfplan
     - Run: terraform apply -auto-approve tfplan

- Keep the workflow minimal and readable.
```

Then briefly show the generated YAML; you don't need to run it live.
