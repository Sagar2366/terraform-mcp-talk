# Demo Prompts — Copy-Paste Ready

Keep this open in a second tab. Copy-paste each prompt when its moment comes.

Everything in this repo — Terraform configs, tests, GitHub Actions workflow, .gitignore — is generated LIVE from these prompts using Kiro.

---

## What You Need Before the Demo

### Local Machine

```bash
terraform version            # >= 1.6 for terraform test
node --version               # >= 18 for npx (skills install)
docker --version             # For MCP server
kiro-cli --version           # Or Kiro Desktop from kiro.dev/downloads
aws sts get-caller-identity  # AWS credentials working
```

### AWS Credentials

Set as environment variables — no files to leak on stage:

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

Use a dedicated demo/sandbox AWS account. **NOT production.**
IAM user needs: EC2, VPC, Security Groups, S3, DynamoDB permissions.

### Terraform State Backend (create once before the demo)

```bash
# Replace YOUR-UNIQUE-BUCKET-NAME with something unique (e.g., demo-tf-state-sagar-2026)

# S3 bucket for remote state
aws s3 mb s3://YOUR-UNIQUE-BUCKET-NAME --region us-east-1
aws s3api put-bucket-versioning \
  --bucket YOUR-UNIQUE-BUCKET-NAME \
  --versioning-configuration Status=Enabled

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### GitHub Repository

1. **Secrets** — Settings → Secrets → Actions:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
2. **Environment** — Settings → Environments → Create `production`:
   - Add yourself as required reviewer (enables human-in-the-loop approval)

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

After generation, run:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Point out insecure defaults: open SSH, no encryption, hardcoded AMI, no tags, local state.

Then destroy immediately:

```bash
terraform destroy -auto-approve
```

---

## Act 2: Install Skills + Verify MCP

**Directory:** `~/demo-terraform-full/` | **Skills:** being installed | **MCP:** active

### Install skills live

```bash
npx -y skills add antonbabenko/terraform-skill
npx -y skills add hashicorp/agent-skills
```

### Verify MCP tools

```
List the Terraform-related tools you have access to right now
and describe each in one short line.
```

### Verify Anton's Terraform Skill

```
Describe what the terraform skill you have loaded is for.
What best practices does it bring to Terraform code generation?
```

### Verify HashiCorp Agent Skills

```
List the HashiCorp Agent Skills you have available and summarize
each in one line. How do they improve the Terraform code you generate?
```

---

## Act 3: Same Prompt + Constraints + Remote State

**Directory:** `~/demo-terraform-full/` | **Skills:** both active | **MCP:** active

**IMPORTANT:** Replace `YOUR-UNIQUE-BUCKET-NAME` with your actual S3 bucket name before pasting.

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
All files in an infra/ directory.

Constraints:
- No hardcoded credentials, API keys, or secrets anywhere.
- No inline security group rules — use aws_vpc_security_group_ingress_rule
  and aws_vpc_security_group_egress_rule resources.
- Variables for region, instance type, and anything that might change.
- All resources tagged: Name, ManagedBy=terraform, Environment, Team.
- EC2 root volume encrypted.
- Security group: ONLY HTTPS (443) inbound from 0.0.0.0/0. No SSH, HTTP, or other ports.
- AWS provider default_tags block for common tags.
- Separate files: main.tf, variables.tf, outputs.tf, backend.tf.
- Data source for AMI lookup — no hardcoded AMI IDs.
- S3 backend: bucket "YOUR-UNIQUE-BUCKET-NAME", key "demo/terraform.tfstate",
  region "us-east-1", dynamodb_table "terraform-locks", encrypt true.

If you cannot satisfy any constraint, say so and explain which one.
```

After generation:

```bash
cd infra/
terraform init
terraform plan
terraform apply -auto-approve
```

Compare side-by-side with Act 1 output.

---

## Act 4: Write Tests (Policy-as-Code)

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

## Act 5: Generate CI/CD Pipeline + Repo Files

### Generate .gitignore

```
Generate a .gitignore file at the repository root for this Terraform project.
It should ignore:
- .terraform/ directories (recursive, all subdirs)
- .terraform.lock.hcl files (recursive)
- *.tfstate and *.tfstate.backup files
- tfplan files
- .kiro/ directory (local IDE config, not needed in repo)

Nothing else. Keep it minimal.
```

### Generate GitHub Actions Workflow

```
Generate a GitHub Actions workflow at .github/workflows/deploy.yml for this
Terraform project. The workflow validates, tests, deploys, and destroys
the infrastructure in infra/ with human-in-the-loop approval.

Trigger on: push to main, pull_request to main, workflow_dispatch.

Global environment variables:
- NODE_VERSION: "22"
- TF_VERSION: "1.12.0"
- TF_WORKING_DIR: infra
- FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"

Jobs (in this exact order with these dependencies):

1. validate-mcp-server (runs on ubuntu-latest):
   - Checkout code
   - Pull Docker image: hashicorp/terraform-mcp-server:latest
   - Send a JSON-RPC initialize request to verify the MCP server responds.
     Use this exact JSON:
     {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"ci-test","version":"1.0.0"}}}
     Pipe it through: timeout 10 docker run -i --rm hashicorp/terraform-mcp-server:latest
     Grep the response for "terraform-mcp-server". Fail the step if not found.

2. validate-skills (runs on ubuntu-latest):
   - Checkout code
   - Setup Node.js with NODE_VERSION
   - Install Anton's Terraform Skill: npx -y skills add antonbabenko/terraform-skill
   - Install HashiCorp Agent Skills: npx -y skills add hashicorp/agent-skills
   - Verify skills installed by searching for SKILL.md:
     find / -name "SKILL.md" -type f 2>/dev/null || true
     Print a success message. Do NOT fail if find returns nothing (install location varies).

3. terraform-validate (needs: validate-mcp-server, validate-skills):
   - Runs on ubuntu-latest, working directory: infra/
   - AWS credentials from secrets (needed for S3 backend during init):
     AWS_ACCESS_KEY_ID from secrets, AWS_SECRET_ACCESS_KEY from secrets,
     AWS_DEFAULT_REGION: us-east-1
   - Checkout code
   - Check that .tf files exist in infra/ — if not, fail with a message:
     "No .tf files found. Generate Terraform from prompts.md, commit to infra/, then push."
   - Install Terraform by downloading the binary via curl from
     releases.hashicorp.com — do NOT use hashicorp/setup-terraform action.
     Use TF_VERSION env var. Download the linux_amd64 zip, unzip to /usr/local/bin/.
   - Run: terraform fmt -check -diff
   - Run: terraform init
   - Run: terraform validate
   - Run terraform test ONLY if tests/*.tftest.hcl files exist. Skip with a
     message if no test files are found.

4. terraform-apply (needs: terraform-validate):
   - Runs on ubuntu-latest, working directory: infra/
   - environment: production (requires manual approval in GitHub)
   - AWS credentials from secrets (same as above)
   - Checkout code
   - Install Terraform via curl (same method as above)
   - Run: terraform init
   - Run: terraform plan -out=tfplan
   - Run: terraform apply -auto-approve tfplan
   - Run: terraform output

5. terraform-destroy (needs: terraform-apply):
   - ONLY runs if terraform-apply succeeded:
     if: always() && needs.terraform-apply.result == 'success'
   - Runs on ubuntu-latest, working directory: infra/
   - environment: production (requires manual approval)
   - AWS credentials from secrets
   - Checkout code
   - Install Terraform via curl (same method as above)
   - Run: terraform init
   - Run: terraform destroy -auto-approve

Important:
- Do NOT use hashicorp/setup-terraform action anywhere — always install via curl.
- The terraform install step should use working-directory: . (repo root, not infra/).
- All terraform commands (fmt, init, validate, test, plan, apply, destroy) run
  in the TF_WORKING_DIR (infra/).
```

### Push Everything

```bash
git add .
git commit -m "feat: add Terraform infra, tests, and CI/CD pipeline

Generated live using Kiro with:
- Anton Babenko's Terraform Skill
- HashiCorp Agent Skills
- Terraform MCP Server"
git push origin main
```

---

## Cleanup (after demo)

Destroy all real AWS resources created by Terraform:

```bash
cd ~/demo-terraform-full/infra/
terraform destroy -auto-approve

cd ~/demo-terraform-naive/
terraform destroy -auto-approve
```

Verify in AWS console:
- EC2 instances terminated
- Security groups deleted (except default)
- VPCs deleted (except default)
- No running costs

### Optional: Remove state backend after all demos are done

```bash
# Empty and delete S3 bucket
aws s3 rm s3://YOUR-UNIQUE-BUCKET-NAME --recursive
aws s3 rb s3://YOUR-UNIQUE-BUCKET-NAME

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks --region us-east-1
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

Refactor this into a production-ready layout following the HashiCorp
Terraform style guide and Anton Babenko's module best practices:

- main.tf, variables.tf, outputs.tf, backend.tf in an infra/ directory
- Proper variable definitions (no hardcoded region/AMI/instance_type)
- Tags: ManagedBy, Environment, Team everywhere
- HTTPS-only security group, encrypted root volume
- No hardcoded credentials, API keys, or secrets
- Use data source for AMI lookup
- S3 backend for remote state

Keep behavior equivalent where safe, and explain the main improvements.
```
