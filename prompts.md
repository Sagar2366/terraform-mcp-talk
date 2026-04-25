# Demo Prompts — Copy-Paste Ready

Keep this open in a second tab. Copy-paste each prompt when its moment comes.

Everything in this repo — Terraform configs, tests, .gitignore — is generated LIVE from these prompts using Kiro.

---

## What You Need Before the Demo

```bash
terraform version            # >= 1.6 for terraform test
node --version               # >= 18 for npx (skills install)
docker --version             # For MCP server
kiro-cli --version           # Or Kiro Desktop from kiro.dev/downloads
```

No AWS credentials needed for the core demo — everything runs with `terraform plan` + `mock_provider`.

### Demo Directories

```bash
# Naive dir — clean, no tools
mkdir -p ~/demo-terraform-naive/

# Full dir — with MCP server config
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

# Pull MCP server image ahead of time
docker pull hashicorp/terraform-mcp-server:latest
```

---

## Act 1: Naive Baseline

**Directory:** `~/demo-terraform-naive/` | **Skills:** none | **MCP:** none

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

Vague on purpose — this is what real engineers actually type.
The point: watch what the AI CHOOSES when you don't specify security.

After generation:

```bash
terraform init
terraform plan
```

Point out insecure defaults in the plan: open SSH, no encryption, hardcoded AMI, no tags, no remote state.

---

## Act 2: Install Skills + Verify MCP

**Directory:** `~/demo-terraform-full/` | **Skills:** being installed | **MCP:** active

### Install skills live

```bash
npx -y skills add antonbabenko/terraform-skill
npx -y skills add hashicorp/agent-skills
```

### Verify MCP tools (quick — one prompt, move on)

```
List the Terraform-related tools you have access to right now
and describe each in one short line.
```

### Verify skills loaded

```
What skills do you have loaded? Summarize each in one line.
```

---

## Act 3: Same Prompt + Constraints

**Directory:** `~/demo-terraform-full/` | **Skills:** both active | **MCP:** active

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
All files in an infra/ directory. Local backend — no remote state.

Constraints:
- No hardcoded credentials, API keys, or secrets anywhere.
- No inline security group rules — use aws_vpc_security_group_ingress_rule
  and aws_vpc_security_group_egress_rule resources.
- Variables for region, instance type, and anything that might change.
- All resources tagged: Name, ManagedBy=terraform, Environment, Team.
- EC2 root volume encrypted.
- Security group: ONLY HTTPS (443) inbound from 0.0.0.0/0. No SSH, HTTP, or other ports.
- AWS provider default_tags block for common tags.
- Separate files: main.tf, variables.tf, outputs.tf.
- Data source for AMI lookup — no hardcoded AMI IDs.

If you cannot satisfy any constraint, say so and explain which one.
```

After generation:

```bash
cd infra/
terraform init
terraform plan
```

Compare side-by-side with Act 1 output. Same intent, wildly different result.

---

## Act 4: Write Tests (Policy-as-Code)

This is the payoff — tests as the contract that catches anything the AI misses.

```
Write a Terraform test file at infra/tests/ec2.tftest.hcl that enforces
these rules for the current configuration in infra/:

1. The EC2 instance type must be t3.micro.
2. The root volume must be encrypted.
3. The security group must allow only HTTPS (443) from 0.0.0.0/0
   and no other ingress from 0.0.0.0/0.
4. All resources must have tags: ManagedBy, Environment, and Team.
5. No hardcoded AMI IDs — must use a data source.
6. No hardcoded credentials or secrets in any .tf file.

Use mock_provider "aws" so tests run without AWS credentials.
Use a single run block with command = "plan" and clear assertions.
```

Then run:

```bash
cd infra/
terraform init
terraform test -filter=tests/ec2.tftest.hcl
```

### Fix Failures

When a test fails, paste the error:

```
terraform test -filter=tests/ec2.tftest.hcl failed with this error:

[PASTE THE ERROR OUTPUT HERE]

Fix ONLY the Terraform configuration so that this test passes.
Do NOT modify any test files.
Do NOT introduce any hardcoded credentials, secrets, or API keys.
Explain briefly what you changed and why.
```

If the TEST has wrong attribute paths (not the TF code):

```
The test failed because some attribute paths were wrong.

Update infra/tests/ec2.tftest.hcl so that all assertions reference
real attributes from the current configuration. Do not weaken the rules.
```

---

## Cleanup

```bash
# Just remove generated files — no AWS resources to destroy
rm -rf ~/demo-terraform-naive/*.tf ~/demo-terraform-naive/.terraform
rm -rf ~/demo-terraform-full/infra/ ~/demo-terraform-full/.terraform
```

---

## Optional Prompts

### Constraint Prompt (standalone security group)

```
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

### Refactor Naive Config

```
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

## Bonus: Real AWS Deployment + CI/CD

**Post-talk content.** Use this if you have extra time or as a repo resource for attendees.

### AWS Prerequisites

```bash
# Set credentials — env vars only, no files
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
aws sts get-caller-identity

# S3 bucket for remote state (native locking in TF >= 1.10, no DynamoDB)
aws s3 mb s3://YOUR-UNIQUE-BUCKET-NAME --region us-east-1
aws s3api put-bucket-versioning \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --versioning-configuration Status=Enabled
```

GitHub repo setup:
1. **Secrets** — Settings > Secrets > Actions: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
2. **Environment** — Settings > Environments > Create `production` with required reviewer

### Add S3 Backend to Existing Config

```
Update the Terraform configuration in infra/ to use an S3 backend:
- bucket: "YOUR-UNIQUE-BUCKET-NAME"
- key: "demo/terraform.tfstate"
- region: "us-east-1"
- use_lockfile: true
- encrypt: true

Put the backend config in infra/backend.tf. Do not change any other files.
```

### Apply to Real AWS

```bash
cd infra/
terraform init
terraform plan
terraform apply -auto-approve
```

### Generate .gitignore

```
Generate a .gitignore for this repo. Ignore:
- .terraform/ directories (recursive)
- .terraform.lock.hcl (recursive)
- *.tfstate and *.tfstate.backup
- tfplan files
- .kiro/ directory

Nothing else.
```

### Generate GitHub Actions Workflow

```
Generate a GitHub Actions workflow at .github/workflows/deploy.yml.
Validates, tests, deploys, and destroys infra/ with human-in-the-loop approval.

Trigger on: push to main, pull_request to main, workflow_dispatch.

Global env vars: NODE_VERSION "22", TF_VERSION "1.12.0", TF_WORKING_DIR infra,
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 "true".

Jobs:

1. validate-mcp-server: pull hashicorp/terraform-mcp-server:latest, send JSON-RPC
   initialize request, grep for "terraform-mcp-server" in response, fail if missing.

2. validate-skills: setup Node.js, npx -y skills add antonbabenko/terraform-skill,
   npx -y skills add hashicorp/agent-skills, search for SKILL.md files.

3. terraform-validate (needs 1+2): working dir infra/, AWS creds from secrets,
   check .tf files exist, install Terraform via curl (NOT setup-terraform action),
   terraform fmt -check, init, validate, test (if test files exist).

4. terraform-apply (needs 3): environment production, AWS creds, install TF via curl,
   init, plan -out=tfplan, apply -auto-approve tfplan, output.

5. terraform-destroy (needs 4, if apply succeeded): environment production, AWS creds,
   install TF via curl, init, destroy -auto-approve.

Do NOT use hashicorp/setup-terraform — install via curl from releases.hashicorp.com.
```

### Push + Deploy

```bash
git add .
git commit -m "feat: Terraform infra, tests, and CI/CD — generated live with Kiro"
git push origin main
```

### Cleanup

```bash
cd infra/
terraform destroy -auto-approve

# Optional: remove state bucket
aws s3 rm s3://YOUR-UNIQUE-BUCKET-NAME --recursive
aws s3 rb s3://YOUR-UNIQUE-BUCKET-NAME
```
