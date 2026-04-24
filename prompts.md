# Demo Prompts — Copy-Paste Ready

Keep this open in a second tab. Copy-paste each prompt when its moment comes.

---

## Act 1: Naive Baseline

**Directory:** `~/demo-terraform-naive` | **Skills:** none | **MCP:** none

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

That's it. Vague on purpose — this is what real engineers actually type.
The point: watch what the AI CHOOSES to do when you don't specify security.

---

## Act 2: Verify Tools + Skills

**Directory:** `~/demo-terraform-full` | **Skills:** being installed | **MCP:** active

After starting Claude in the full dir:

```
List the Terraform-related tools and skills you have access to right now, and briefly describe each one in one line.
```

After installing Anton's skill:

```
In one or two sentences, describe what the terraform skill you have loaded is for.
```

After installing HashiCorp Agent Skills:

```
List the HashiCorp Agent Skills you have available and summarize each in one line.
```

---

## Act 3: Same Prompt, With MCP + Skills Active

**Directory:** `~/demo-terraform-full` | **Skills:** both active | **MCP:** active

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

EXACT same prompt as Act 1. The point: same input, different output.
The improvement comes from skills + MCP, not from a better prompt.

---

## Act 4: Write Tests (Policy-as-Code)

```
Write a Terraform test file at tests/ec2.tftest.hcl that enforces these rules
for the current configuration:

1. The EC2 instance type must be t3.micro.
2. The root volume must be encrypted.
3. The security group must allow only HTTPS (443) from 0.0.0.0/0
   and no other ingress from 0.0.0.0/0.
4. All resources must have tags: ManagedBy, Environment, and Team.

Use mock_provider "aws" so tests run without AWS credentials.
Use a single run block with command = "plan" and clear assertions.
```

Claude Code will write the file directly. No manual copy needed.

Then run:

```bash
terraform init
terraform test -filter=tests/ec2.tftest.hcl
```

---

## Act 4: Fix Failures

When a test fails, paste the error:

```
terraform test -filter=tests/ec2.tftest.hcl failed with this error:

[PASTE THE ERROR OUTPUT HERE]

Fix ONLY the Terraform configuration so that this test passes.
Do NOT modify any test files.
Explain briefly what you changed and why.
```

Then rerun:

```bash
terraform test -filter=tests/ec2.tftest.hcl
```

If the TEST has wrong attribute paths (not the TF code):

```
The test failed because some attribute paths were wrong.

Update tests/ec2.tftest.hcl so that all assertions reference real attributes
from the current configuration. Do not weaken the rules.
```

---

## Optional: Constraint Prompt

```
Generate ONLY an aws_security_group resource that:

- Belongs to variable vpc_id
- Allows ingress HTTPS (443) from 0.0.0.0/0
- Does NOT allow any other ingress from 0.0.0.0/0 on any port
- Has a description on every rule
- Has tags Name, ManagedBy, Environment, Team

If you cannot satisfy one of these constraints, say so explicitly
and explain which one.
```

---

## Optional: Refactor Naive Config

```
Here is a naive single-file Terraform config for VPC + subnet + EC2:

[PASTE ~/demo-terraform-naive/main.tf HERE]

Refactor this into a production-ready layout:

- main.tf, variables.tf, outputs.tf
- Proper variable definitions (no hardcoded region/AMI/instance_type)
- Tags: ManagedBy, Environment, Team everywhere
- HTTPS-only security group, encrypted root volume

Keep behavior equivalent where safe, and explain the main improvements.
```
