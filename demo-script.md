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

The problem? When you don't specify security, the AI fills in the blanks with the laziest defaults:

- SSH open to the internet because 'you might need it',
- unencrypted volumes because you didn't say 'encrypt',
- and everything hardcoded into one `main.tf` because you said 'keep it simple'.

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

"This is the kind of prompt a real engineer types at 5pm on a Friday."

Paste:

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

**[That's it. Vague. No security requirements. No structure demands. Just like real life.]**

Let it run. Then in Terminal 2:

```bash
cd ~/demo-terraform-naive
cat main.tf
```

**[Now look at what the AI CHOSE to do on its own:]**

On camera, point at the decisions the AI made WITHOUT you asking:

- Did it open SSH (22) to `0.0.0.0/0`? You didn't ask for SSH access — it added it "to be helpful"
- Did it use HTTP (80) instead of HTTPS (443)? You said "web app" — it assumed unencrypted
- Is the root volume encrypted? You didn't say "don't encrypt" — but it defaulted to no encryption
- Are there any tags? Any variables? Or is everything hardcoded?
- Is it one giant `main.tf`?
- Any tests? Any CI? Any outputs?

"I did NOT ask for port 22. I did NOT say 'skip encryption.' I said 'deploy a web app, keep it simple.' The AI filled in every gap with the laziest possible default. THAT is the real problem — it's not what you ask for that's dangerous, it's what you DON'T ask for."

Line:

"The AI is not malicious. It's helpful. And helpful without guardrails means: take the shortest path, skip everything you didn't explicitly mention, and hand it to you with a smile."

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

In Terminal 2 (or in Claude):

```bash
# Option A: npx skills (works outside Claude)
npx skills add hashicorp/agent-skills

# Option B: Claude Code plugin system
claude plugin marketplace add hashicorp/agent-skills
claude plugin install terraform-code-generation@hashicorp
```

(Try Option A first during dry-run. If that's slow, use Option B. If both are slow live, say you have them pre-installed.)

Check:

```
List the HashiCorp Agent Skills you have available and summarize each in one line.
```

You want to see style guide, tests, Stacks, provider dev, Packer, etc.

Don't explain each — just:

"Okay, it has a Terraform style guide, testing patterns, and product-specific skills loaded."

---

## Act 3 — Same Ask, But Now "Safe Terraform" (10-12 min)

**Goal:** show clear before/after. USE THE SAME VAGUE PROMPT — let tools do the work.

Still in `~/demo-terraform-full` in Claude:

```
I need to deploy a small web application on AWS.
Set up the networking and compute. Keep it simple.
```

**[EXACT same prompt as Act 1. This is critical — the audience must see that the PROMPT didn't change, only the tools behind it.]**

Let it run.

Now in Terminal 2:

```bash
ls
cat main.tf
cat variables.tf
cat outputs.tf
```

On camera, compare with the naive output:

- Did it create separate files this time? (variables.tf, outputs.tf)
- Did it default to HTTPS instead of HTTP?
- Did it skip SSH, or at least restrict it to a specific CIDR?
- Is the root volume encrypted without us asking?
- Are there tags?
- Did it use variables instead of hardcoding?

"Same prompt. Word for word. I didn't ask for encryption. I didn't ask for tags. I didn't ask for separate files. The SKILLS added those defaults. The MCP server made sure the argument names are correct. The AI is the same — the context around it changed."

**This is the honest demo moment. Same input, different output, because of tools — not because of a better prompt.**

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
```

**[Claude Code will write the file directly to tests/ec2.tftest.hcl. Don't manually copy anything.]**

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

"You've just seen:

1. **Naked LLM + vague prompt** — it 'works' but fills every gap with the laziest default. SSH open, no encryption, no tags, no tests.
2. **Same prompt + MCP + skills** — same two lines, but now the AI has expert knowledge and live docs. It CHOSE encryption, CHOSE proper structure, CHOSE better security defaults — without us asking.
3. **Tests as the contract** — even with all the guardrails, we don't trust. We verify. `terraform test` catches anything the AI misses.

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
