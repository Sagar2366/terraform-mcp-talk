# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

> Duration: ~40-45 min | Format: 100% Live Demo, No Slides | Presenter: Sagar Utekar

---

## Pre-Demo Setup (do before the talk)

- Have two empty dirs ready: `~/demo-terraform-naive` and `~/demo-terraform-full`
- MCP config only in `~/demo-terraform-full/.claude/settings.json`
- No skills installed at the very start (`rm -rf ~/.claude/skills`)

**Terminals:**

- Terminal 1: Claude Code (main demo) — full screen, dark theme, big font.
- Terminal 2: Shell + vim/code to show generated files when needed.

---

## Opening (2 min, on camera, no terminal)

"Everyone says: 'Just ask AI to write your Terraform.'
And it works. It spits out HCL that plans and often even applies.

The problem? It also happily:

- opens `0.0.0.0/0` on port 22,
- creates unencrypted volumes and buckets,
- and hard-codes everything into one `main.tf` with allow-all IAM.

LLMs are trained to be helpful. They want to close the chat loop fast. So they take the shortest path to 'works on my dev account' and hand it to you with a smile.

The issue isn't that AI can't write Terraform. It can. The issue is:
**How do you trust what comes out?**

I'm going to show you, live, how we put guardrails around AI-generated Terraform using:

- the Terraform MCP server,
- HashiCorp Agent Skills,
- a Terraform best-practices skill from the community,
- and `terraform test`.

No slides. Just terminals. Let's go."

---

## Act 1 — Naive AI Terraform (5-6 min)

**Goal:** show "it works but it's scary".

### Step 1.1 — Go to naive dir, start Claude

Terminal 1:

```bash
cd ~/demo-terraform-naive
claude
```

Say:

"This directory has no MCP config, no skills. Just a naked LLM."

### Step 1.2 — Naive prompt

Paste:

```
Create a single-file Terraform configuration (main.tf) that:

- Uses the AWS provider in us-east-1
- Creates a VPC, a public subnet, and an EC2 instance
- Opens SSH (22) and HTTP (80) from the internet
- Uses any AMI and instance type you like

Do not split into modules, tests, or CI. Just make it "work".
```

Let it run. Then in Terminal 2:

```bash
cd ~/demo-terraform-naive
cat main.tf
```

On camera, quickly point at:

- `0.0.0.0/0` on 22 and 80
- no encryption on the root volume
- no tags
- everything hardcoded
- single `main.tf`

Line:

"This will probably plan and apply. It's also a great way to get paged at 3am."

**Transition:**

"Now I'll turn on a couple of pieces and we'll see how the exact same request behaves."

---

## Act 2 — Turn on MCP and Skills (10-12 min)

**Goal:** same kind of ask, much better output.

### Step 2.1 — Switch to full demo dir with MCP config

Terminal 2:

```bash
cd ~/demo-terraform-full
cat .claude/settings.json
```

Show:

```json
{
  "mcpServers": {
    "terraform": {
      "command": "npx",
      "args": ["-y", "terraform-mcp-server"],
      "env": {}
    }
  }
}
```

Say briefly:

"This tells Claude to spin up the Terraform MCP server so it can read live registry docs instead of guessing."

### Step 2.2 — Start Claude with no skills and verify MCP tools

Terminal 1:

```bash
cd ~/demo-terraform-full
claude
```

Prompt:

```
List the Terraform-related tools you have access to right now and describe each in one short line.
```

Confirm some MCP tools appear. Don't dwell.

### Step 2.3 — Install Anton's Terraform Skill (community best-practices)

In Terminal 2:

```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
```

Back to Terminal 1, restart Claude:

```
exit
claude
```

Quick prompt:

```
In one or two sentences, describe what the terraform skill you have loaded is for.
```

You want something along the lines of "Terraform/OpenTofu best practices, modules, tests, CI/CD".

### Step 2.4 — Install HashiCorp Agent Skills (official product skills)

In Claude:

```
/plugin marketplace add hashicorp/agent-skills
```

(Or if that's slow, skip the UI and just say you have them installed.)

Check:

```
List the HashiCorp Agent Skills you have available and summarize each in one line.
```

You want to see style guide, tests, Stacks, provider dev, Packer, etc.

Don't explain each — just:

"Okay, it has a Terraform style guide, testing patterns, and product-specific skills loaded."

---

## Act 3 — Same Ask, But Now "Safe Terraform" (10-12 min)

**Goal:** show clear before/after.

Still in `~/demo-terraform-full` in Claude:

```
I want a production-ready Terraform setup for a tiny web EC2 instance.

Requirements:

- Use the AWS provider in us-east-1
- Create:
  - a VPC with one public subnet
  - a security group that allows ONLY HTTPS (443) from the internet
  - a single t3.micro EC2 instance in that subnet
- Enforce:
  - encrypted root volume
  - required tags on all resources: ManagedBy, Environment, Team
- Structure as:
  - main.tf
  - variables.tf
  - outputs.tf

Before writing any code, use whatever Terraform tools or skills you have
to read the AWS provider and the aws_vpc, aws_subnet, aws_security_group,
and aws_instance docs from the Terraform Registry. Do NOT invent arguments.
Then generate the configuration.
```

Let it run.

Now in Terminal 2:

```bash
ls
cat main.tf
cat variables.tf
cat outputs.tf
```

On camera, quickly compare with naive:

- Variables instead of hardcoded region/AMI/type
- Only 443 from `0.0.0.0/0`
- Encrypted root volume
- Tags present
- Multiple files instead of a giant `main.tf`

Line:

"Same model, similar ask. The only difference is: now it's reading live docs through MCP and following Terraform best-practices and HashiCorp style skills."

**Don't over-explain MCP/skills here. The demo itself is the point.**

---

## Act 4 — terraform test: Make the Tests Do the Talking (10-12 min)

**Goal:** show tests catching issues and AI fixing them.

### Step 4.1 — Ask Claude to write a test file

In Claude (still in `~/demo-terraform-full`):

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
Do not change my existing *.tf files, just output the test file content.
```

Copy the output into files. Terminal 2:

```bash
mkdir -p tests/mocks
# paste ec2.tftest.hcl content from Claude into tests/ec2.tftest.hcl
cat > tests/mocks/aws.tfmock.hcl << 'EOF'
mock_provider "aws" {}
EOF
```

### Step 4.2 — Run the tests

Terminal 2:

```bash
terraform init
terraform test -filter=tests/ec2.tftest.hcl
```

If it passes first try, great. If it fails (likely due to attribute paths), even better.

**On failure:**

"Good. The test is stricter than the code. That's what we want."

Grab the error text, then in Claude:

```
terraform test -filter=tests/ec2.tftest.hcl failed with this error:

[PASTE the failing assertion or last few lines]

Update tests/ec2.tftest.hcl so that all assertions reference real attributes
from the current configuration. Keep the rules exactly the same.
Do not change my *.tf files.
```

Update the file, rerun:

```bash
terraform test -filter=tests/ec2.tftest.hcl
```

When it goes green:

"Now the AI had to satisfy the test, not the other way around. I don't care who wrote the Terraform — human or AI — they all have to pass the same contract."

**That's your big "tests doing work" moment.**

---

## Optional Mini-Act — Constraint Prompt (2-3 min)

If you have time, quickly show how a good prompt can harden a single resource:

In Claude:

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

Just enough to show "prompts as policy" without staying long.

---

## Closing (2-3 min, on camera)

"You've just seen the exact same idea three times:

1. **Naive LLM Terraform** — it 'works' but is unsafe and unreviewable.
2. **LLM + MCP + skills** — same ask, but now it uses live Terraform docs and best practices, so the shape of the config is much closer to something you'd actually ship.
3. **LLM + tests** — Terraform's native tests become the contract. The AI has to satisfy your policy encoded as code.

The stack is simple:

- **MCP:** gives the model current Terraform knowledge.
- **Skills:** inject best practices and product patterns.
- **Prompts:** describe what you want, precisely.
- **`terraform test`:** enforces what's acceptable.

The future isn't 'AI writes Terraform and you pray.'
It's: AI writes, tests verify, humans review the contract — not 500 lines of HCL.

Thanks."

---

## Links

- Anton Babenko's Terraform Skill: https://github.com/antonbabenko/terraform-skill
- HashiCorp Agent Skills: https://github.com/hashicorp/agent-skills
- Terraform MCP Server: https://github.com/hashicorp/terraform-mcp-server
- Terraform Test Docs: https://developer.hashicorp.com/terraform/language/tests
- HashiCorp Blog: https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills
