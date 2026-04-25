# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

> Duration: ~40-45 min | Format: 100% Live Demo, No Slides | Presenter: Sagar Utekar

---

## Pre-Demo Setup (do before the talk)

- Have two empty dirs ready: `~/demo-terraform-naive` and `~/demo-terraform-full`
- MCP config only in `~/demo-terraform-full/`.kiro/settings/mcp.json``
- No skills installed at the very start (verify skill location during dry-run)

**Terminals:**

- Terminal 1: Kiro (main demo) — full screen, dark theme, big font.
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

### Step 1.1 — Go to naive dir, start Kiro

Terminal 1:

```bash
cd ~/demo-terraform-naive
kiro-cli
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
cat `.kiro/settings/mcp.json`
```

Show:

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

Say briefly:

"This tells Kiro to spin up the Terraform MCP server so it can read live registry docs instead of guessing."

### Step 2.2 — Start Kiro with no skills and verify MCP tools

Terminal 1:

```bash
cd ~/demo-terraform-full
kiro-cli
```

Prompt:

```
List the Terraform-related tools you have access to right now and describe each in one short line.
```

Confirm some MCP tools appear. Don't dwell.

### Step 2.3 — Install Anton's Terraform Skill (community best-practices)

**NOTE:** Skill loading in Kiro may differ from Kiro. During dry-run,
verify: (1) where `npx skills add` installs to, (2) whether Kiro picks up
skills from that location, (3) or whether you need to use Kiro's custom
agent config to include the skill.

In Terminal 2:

```bash
# Option A: npx skills (IDE-agnostic)
npx skills add antonbabenko/terraform-skill

# Option B: manual clone (verify the target path during dry-run)
git clone https://github.com/antonbabenko/terraform-skill.git ~/.kiro/skills/terraform
```

Back to Terminal 1, restart Kiro:

```
exit
kiro-cli
```

Quick prompt:

```
In one or two sentences, describe what the terraform skill you have loaded is for.
```

You want something along the lines of "Terraform/OpenTofu best practices, modules, tests, CI/CD".

### Step 2.4 — Install HashiCorp Agent Skills (official product skills)

In Terminal 2 (or in Kiro):

```bash
# npx skills (works across IDEs including Kiro)
npx skills add hashicorp/agent-skills
```

(Try during dry-run first. If it's slow live, say you have them pre-installed.)

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

Still in `~/demo-terraform-full` in Kiro:

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

### Step 4.1 — Ask Kiro to write a test file

In Kiro (still in `~/demo-terraform-full`):

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

**[Kiro will write the file directly to tests/ec2.tftest.hcl. Don't manually copy anything.]**

### Step 4.2 — Run the tests

Terminal 2:

```bash
terraform init
terraform test -filter=tests/ec2.tftest.hcl
```

If it passes first try, great. If it fails (likely due to attribute paths), even better.

**On failure:**

"Good. The test is stricter than the code. That's what we want."

Grab the error text, then in Kiro:

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

In Kiro:

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
- MCP Protocol: https://modelcontextprotocol.io/introduction
- MCP Architecture: https://modelcontextprotocol.io/docs/concepts/architecture

---
---

# PERSONAL NOTES — Theory Cheat Sheet (NOT for the audience)

> This section is Sagar's personal prep material. Read it once, internalize it,
> then explain it in your own words during the demo. None of this is shown to the audience.

---

## The Big Picture — How Everything Connects

Start with the full picture in your head, then we'll break each piece down below.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           YOU (the engineer)                            │
│                                                                         │
│   "Create a production-ready EC2 with encrypted volume and HTTPS SG"   │
└──────────────────────────────────┬──────────────────────────────────────┘
                                   │ your prompt
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLAUDE CODE (AI Agent)                          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     CONTEXT WINDOW                               │   │
│  │                                                                   │   │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐   │   │
│  │  │  Anton's Skill   │  │ HashiCorp Skills  │  │  Your Prompt  │   │   │
│  │  │                  │  │                   │  │               │   │   │
│  │  │ • Module layout  │  │ • Style guide     │  │ • EC2 instance│   │   │
│  │  │ • Testing        │  │ • Stacks patterns │  │ • HTTPS only  │   │   │
│  │  │ • CI/CD          │  │ • Provider dev    │  │ • Encrypted   │   │   │
│  │  │ • Security       │  │ • Refactoring     │  │ • Tagged      │   │   │
│  │  │ • tflint/tfsec   │  │ • Packer          │  │               │   │
│  │  └─────────────────┘  └──────────────────┘  └───────────────┘   │   │
│  │              ▲                    ▲                                │   │
│  │              │                    │                                │   │
│  │      loaded at startup     loaded at startup                      │   │
│  │    (git clone → skills/)   (plugin install)                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  During code generation, the AI calls MCP tools:                          │
│  "I need to look up aws_instance docs before writing..."                  │
│                                   │                                     │
└───────────────────────────────────┼─────────────────────────────────────┘
                                    │ MCP tool call (JSON-RPC over stdio)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      TERRAFORM MCP SERVER                               │
│                      (runs as child process)                            │
│                                                                         │
│  Exposed tools (real names from source):                                 │
│  ┌──────────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ search_providers     │  │ get_module_       │  │ get_provider_    │  │
│  │ search_modules       │  │ details           │  │ details          │  │
│  │                      │  │                   │  │                  │  │
│  │ Find providers and   │  │ Module inputs,    │  │ Provider schema, │  │
│  │ modules by keyword   │  │ outputs, versions │  │ argument names,  │  │
│  │ in the registry      │  │ and dependencies  │  │ types, defaults  │  │
│  └──────────┬───────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│             │                       │                      │            │
└─────────────┼───────────────────────┼──────────────────────┼────────────┘
              │                       │                      │
              └───────────┬───────────┘──────────────────────┘
                          │ HTTPS API calls
                          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    TERRAFORM REGISTRY                                    │
│                  registry.terraform.io                                   │
│                                                                         │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────────────┐  │
│  │    Providers     │  │     Modules      │  │    Documentation      │  │
│  │                  │  │                  │  │                       │  │
│  │ aws v5.82.0     │  │ vpc v5.16.0      │  │ aws_instance args:    │  │
│  │ azurerm v4.x    │  │ eks v20.31.0     │  │  • ami                │  │
│  │ google v6.x     │  │ s3-bucket v4.x   │  │  • instance_type      │  │
│  │ 4000+ more...   │  │ 15000+ more...   │  │  • root_block_device  │  │
│  └─────────────────┘  └──────────────────┘  │    └─ encrypted       │  │
│                                              │    └─ volume_size     │  │
│                                              └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## What is MCP? (Model Context Protocol)

**The one-liner:** MCP is a USB port for AI — plug in any data source and the
AI can read from it.

**Official source:** https://modelcontextprotocol.io/introduction

**The real explanation:**

Socho ek situation. Tum Kiro se bolo "AWS VPC module use kar ke Terraform likh do."
AI kya karega? Apne training data se likhega. Training data kab ka hai? 6 months
purana. 1 saal purana. Module ka version change ho gaya. Arguments change ho gaye.
Naye arguments aaye. AI ko pata hi nahi.

Yahi problem MCP solve karta hai.

MCP ek open standard hai — Anthropic ne banaya — jo AI models ko real-time data
sources se connect karta hai. Ek protocol hai, jaise HTTP web ke liye hai, waise
MCP AI tools ke liye hai.

```
Without MCP:
  You ask the AI → AI guesses from training data → Maybe correct, maybe hallucinated

With MCP:
  You ask the AI → AI calls MCP server → MCP reads LIVE docs from registry.terraform.io
  → AI gets real argument names, types, defaults → Generates correct code
```

**How it works technically:**

1. You configure an MCP server in `.kiro/settings/mcp.json`
2. When Kiro starts, it connects to that server via stdio (stdin/stdout)
3. The server exposes "tools" — functions the AI can call
4. The AI decides WHEN to call which tool based on your prompt
5. The tool returns real data — the AI uses that data to generate code

### MCP Protocol — How the Pipe Works

```
┌──────────────┐          stdio (stdin/stdout)         ┌──────────────────┐
│              │  ──────── JSON-RPC messages ────────▶  │                  │
│  Kiro │                                        │  MCP Server      │
│  (MCP Client)│  ◀──────── tool results ────────────  │  (terraform-mcp) │
│              │                                        │                  │
└──────────────┘                                        └──────────────────┘

Step-by-step during generation:

1. The AI reads your prompt
   "...deploy a small web app on AWS..."

2. The AI (guided by skills) decides it needs resource docs
   → Calls MCP tool: get_provider_details("hashicorp/aws")

3. MCP server receives the call
   → Hits registry.terraform.io for current provider docs

4. MCP server returns real documentation
   ← Actual argument names, types, required fields, defaults

5. The AI uses REAL argument names to generate Terraform
   → No hallucination. No guessing. Real data.
```

> The official MCP architecture follows a Host → Client → Server model.
> Kiro is the Host, it creates MCP Clients (one per server),
> each Client connects to one MCP Server (like terraform-mcp-server).
> See: https://modelcontextprotocol.io/docs/concepts/architecture

**Terraform MCP server tools (real names from source code):**

| Toolset | Tools | What they do |
|---------|-------|-------------|
| Registry (default) | `search_providers`, `get_provider_details`, `get_latest_provider_version`, `get_provider_capabilities` | Find and read provider docs from registry.terraform.io |
| Registry (default) | `search_modules`, `get_module_details`, `get_latest_module_version` | Find and read module docs, inputs, outputs |
| Registry (default) | `search_policies`, `get_policy_details` | Find Sentinel policy sets |
| Terraform (opt-in) | `list_workspaces`, `create_run`, `get_plan_details`, etc. | HCP Terraform / TFE workspace management |

Source: `github.com/hashicorp/terraform-mcp-server/pkg/toolsets/mapping.go`

**Why it matters for Terraform specifically:**

Terraform has 4000+ providers. Each provider has hundreds of resources.
Each resource has dozens of arguments. Arguments change between versions.
No LLM can memorize all of this accurately. MCP means it doesn't have to —
it just looks it up.

**Analogy for the audience:**

"Imagine you are writing an exam. Without MCP, you are writing from memory.
With MCP, you have the textbook open. Same student, same brain, but now
you are looking up the exact answer instead of guessing."

---

## What are Agent Skills?

**The one-liner:** Skills are textbooks you give to the AI before it starts working.

**The real explanation:**

Dekho, LLM ko bahut cheezein pata hain. But "pata hona" aur "sahi tarike se
karna" mein farak hai. Ek junior developer ko Python aata hai. But kya wo
production-ready code likhega? Nahi. Kyunki uske paas patterns nahi hain.
Experience nahi hai. Best practices nahi hain.

Skills wohi experience dete hain AI ko.

Anthropic ne ek open standard banaya — Agent Skills format. Ek skill basically
ek folder hai jisme:

- Instructions hain (do this, don't do that)
- Reference materials hain (examples, patterns, anti-patterns)
- Context hai (what framework, what conventions, what tools to use)

Jab tum skill load karte ho, Kiro ke context window mein ye sab inject
ho jata hai. Ab AI sirf apne training data se nahi likh raha — wo ek
expert ki guidance follow kar raha hai.

### How Skills Load — Architecture

**Verified from GitHub repos (Apr 2026):**

```
(Skills directory — verify exact path in Kiro)     Kiro context window
                                                     ┌─────────────────────────┐
Anton's skill         ──── loaded ────▶              │                         │
  └── SKILL.md               at                      │  System prompt          │
     (community skill)       startup                 │  + Anton's skill rules  │
                                                     │  + HashiCorp skill rules│
                                                     │  + Your prompt          │
HashiCorp Agent Skills:                              │                         │
  installed via                                      │  "When writing TF:      │
  npx skills add             loaded                  │   - always use modules  │
                             at                      │   - encrypt by default  │
agent-skills/         ──── startup ───▶              │   - write tests         │
├── terraform/                                       │   - follow HC style     │
│   ├── code-generation/                             │   - use default_tags    │
│   │   └── skills/                                  │   - run tflint/tfsec"   │
│   │       ├── terraform-                           │                         │
│   │       │   style-guide/                         └─────────────────────────┘
│   │       │   └── SKILL.md                                   │
│   │       └── write-run-                          Kiro uses these rules
│   │           tests/                              while generating code
│   │           └── SKILL.md                                   │
│   ├── module-generation/                                     ▼
│   │   └── skills/                          ┌─────────────────────────┐
│   │       └── .../                         │  Generated Terraform     │
│   └── provider-development/                │  that follows ALL        │
│       └── skills/                          │  loaded skill rules      │
│           └── .../                         └─────────────────────────┘
└── packer/
    └── .../

Key insight:
  Skills are NOT code. Skills are INSTRUCTIONS.
  They don't execute. They guide.
  Like a style guide pinned above your desk — you read it, then write code.
```

NOTE: Kiro's skill loading mechanism may differ from Claude Code's
`~/.claude/skills/` directory. Use `npx skills add` (IDE-agnostic) or
verify during dry-run where Kiro expects skill files.

**Two types of skills in our demo:**

### 1. Anton Babenko's Terraform Skill (Community)

Anton kaun hai? Terraform community mein sabse bada naam. Uske modules —
terraform-aws-modules — hundreds of millions of times download hue hain.
Jab wo bolta hai "Terraform aise likho" — industry sunta hai.

Usne apna experience package kiya ek skill mein:

- **Engine:** init → validate → plan → apply. Steps mat skip karo.
- **Guardrails:** Modular code likho. Ek file mein sab mat dalo.
  Naming conventions follow karo. Tags lagao.
- **Expert patterns:** Nested for_each, dynamic blocks, complex logic
  sahi tarike se handle karo. Hallucinate mat karo — docs padho.
- **Toolchain:** tflint, tfsec, infracost — ye tools generation process
  mein integrate karo. Sirf code mat do, security scan bhi karo,
  cost estimate bhi do.

**What changes when you load it:**

```
Without skill:                    With Anton's skill:
─────────────────────────────     ─────────────────────────────
Single main.tf                    modules/{name}/main.tf, variables.tf, outputs.tf
No tests                          .tftest.hcl with mocks + integration
No CI                             GitHub Actions: fmt/validate/tflint/tfsec/test
Encryption optional               Encryption ON by default
Hardcoded everything              Variables with types + descriptions
No cost awareness                 Infracost in CI
```

Install: `npx skills add antonbabenko/terraform-skill` (or `git clone` — verify path during dry-run)

### 2. HashiCorp Agent Skills (Official)

HashiCorp ne February 2026 mein release kiya. Ye community nahi hai —
ye VENDOR ki official guidance hai. HashiCorp khud bol raha hai
"hamare tools aise use karo."

**What's in the box:**

| Skill | Kya karta hai |
|-------|--------------|
| Terraform Style Guide | HashiCorp ki documented naming, formatting, tagging conventions. GitHub pe jo popular hai wo nahi — jo HashiCorp recommend karta hai wo. |
| Write & Run Tests | `.tftest.hcl` syntax, mock providers, unit vs integration patterns. HashiCorp ka recommended testing approach. |
| Terraform Stacks | Multi-environment, multi-region orchestration. HCP Terraform / TFE ke saath kaise use karna hai. |
| Provider Development | Agar tum Terraform provider bana rahe ho — plugin framework, schema design, lifecycle methods, testing. |
| Module Refactoring | Monolithic `main.tf` ko clean modules mein todna. |
| Packer | AWS, Azure, Windows image building with HCP Packer integration. |

Install (from agent-skills README):
```bash
# IDE-agnostic (works with Kiro, Cursor, Claude Code, etc.)
npx skills add hashicorp/agent-skills
```

**Difference between Anton's skill and HashiCorp's skills:**

```
Anton's skill = "How a good Terraform practitioner writes code"
  → Community best practices
  → Works across all providers and clouds
  → Testing, modules, CI/CD, security patterns
  → Think: senior engineer's playbook

HashiCorp's skills = "How HashiCorp wants you to use THEIR products"
  → Official vendor guidance
  → Product-specific (Terraform, Packer, Stacks)
  → Style guide from the source
  → Think: vendor's documentation distilled into instructions
```

Dono saath mein kaam karte hain. Anton bolta hai "aise likho."
HashiCorp bolta hai "aur specifically hamare tool mein aise karo."

---

## MCP vs Skills — Kya Farak Hai?

Ye sabse common confusion hai. Clear kar lo:

```
MCP = PIPE (data delivery)
  → Brings real-time data TO the AI
  → Registry docs, module schemas, provider versions
  → Changes every time a provider updates
  → Without MCP: AI guesses from training data
  → With MCP: AI reads live documentation

Skills = TEXTBOOK (knowledge + patterns)
  → Teaches the AI HOW to use data correctly
  → Best practices, conventions, anti-patterns
  → Doesn't change day-to-day (practices evolve slowly)
  → Without skills: AI writes "works but messy" code
  → With skills: AI writes production-grade code
```

### Side-by-Side Comparison

```
┌────────────────────┬──────────────────────┬──────────────────────┐
│    MCP SERVER      │    AGENT SKILLS      │   TERRAFORM TEST     │
│    (the pipe)      │    (the textbook)    │   (the contract)     │
├────────────────────┼──────────────────────┼──────────────────────┤
│                    │                      │                      │
│ WHAT it gives:     │ WHAT it gives:       │ WHAT it gives:       │
│ Real-time data     │ Expert knowledge     │ Pass/fail verdict    │
│                    │                      │                      │
│ WHEN it acts:      │ WHEN it acts:        │ WHEN it acts:        │
│ During generation  │ Before generation    │ After generation     │
│ (on-demand calls)  │ (loaded at startup)  │ (explicit run)       │
│                    │                      │                      │
│ WITHOUT it:        │ WITHOUT it:          │ WITHOUT it:          │
│ AI guesses args    │ AI writes messy code │ You review 500 lines │
│ from training data │ that "works" but     │ of HCL manually and  │
│ → hallucination    │ isn't production     │ pray you catch the   │
│   risk             │ grade                │ security bug         │
│                    │                      │                      │
│ WITH it:           │ WITH it:             │ WITH it:             │
│ AI reads LIVE docs │ AI follows expert    │ 5 assertions catch   │
│ → correct args     │ patterns → clean,    │ what humans miss     │
│ → correct versions │ modular, secure code │ → automated safety   │
│                    │                      │                      │
│ ANALOGY:           │ ANALOGY:             │ ANALOGY:             │
│ Open-book exam     │ Culinary school      │ Health inspection    │
│ (look up answers)  │ (learn to cook)      │ (pass or no permit)  │
│                    │                      │                      │
│ CHANGES:           │ CHANGES:             │ CHANGES:             │
│ Every time a       │ Slowly — practices   │ When YOUR policy     │
│ provider updates   │ evolve over months   │ changes              │
│                    │                      │                      │
└────────────────────┴──────────────────────┴──────────────────────┘
```

**Analogy:**

"MCP is like giving a chef access to a recipe book that updates in real-time.
Skills are like sending that chef to culinary school. The recipe book tells you
WHAT ingredients to use. Culinary school teaches you HOW to cook properly.
You need both."

**Or simpler:**

"MCP = current data. Skills = expert knowledge. Tests = the contract."

---

## Why terraform test?

**The one-liner:** Skills and MCP make the AI BETTER. Tests make it ACCOUNTABLE.

**Official docs:** https://developer.hashicorp.com/terraform/language/tests

**The real explanation:**

Sab kuch sahi kar lo — MCP lagao, skills lagao, best prompt likho.
Phir bhi AI galti kar sakta hai. Kyunki AI is probabilistic. Har baar
same output nahi dega. Ek baar encryption on karega, dusri baar bhool
jayega.

`terraform test` is the contract. It doesn't care WHO wrote the code —
human ya AI. It just checks: does this code satisfy these rules?

**How terraform test works:**

```hcl
# tests/ec2.tftest.hcl

mock_provider "aws" {}     # <-- No real AWS needed. Fake provider.

run "security_checks" {
  command = plan            # <-- Just plan, don't apply

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted == true
    error_message = "Root volume must be encrypted"
  }

  assert {
    condition     = !contains(aws_security_group.web.ingress[*].cidr_blocks, ["0.0.0.0/0"])
                    || aws_security_group.web.ingress[0].from_port == 443
    error_message = "Only HTTPS (443) allowed from 0.0.0.0/0"
  }
}
```

**Key points:**

- Built into Terraform CLI since v1.6. No external tools needed.
- `mock_provider` = tests run without AWS credentials. Zero cost.
- `command = plan` = validates configuration shape, not live infra.
- Each `assert` is a security policy written as code.
- Fails fast — broken config never reaches `terraform apply`.

**The workflow:**

```
1. Human writes the TEST (the policy — what must be true)
2. AI writes the TERRAFORM (the implementation)
3. terraform test checks if implementation satisfies policy
4. If fail → AI fixes → rerun → repeat until green
5. Human reviews the TEST, not 500 lines of HCL
```

**Why this matters for AI-generated code specifically:**

When a human writes Terraform, you do code review. 500 lines, 2 hours,
still might miss something. When AI writes Terraform, it generates
500 lines in 30 seconds. You cannot review that fast enough.

But you CAN write 5 test assertions in 2 minutes. Those 5 assertions
cover the security policies that matter. Now you review 5 lines of test,
not 500 lines of HCL.

**Analogy:**

"Terraform test is like a unit test for infrastructure policy. You don't
test that the code runs — you test that the code is SAFE. Same idea as
a linter, but for your security and compliance rules."

---

## The Full Stack — How All Three Work Together

```
YOUR PROMPT
  "Create an EC2 instance with encrypted volume and HTTPS-only SG"
    │
    ▼
SKILLS (loaded into the AI's context)
  Anton's: "Use modules, add tests, encrypt by default, run tflint"
  HashiCorp's: "Follow our style guide, use default_tags, structure files this way"
    │
    ▼
MCP SERVER (called during generation)
  "Let me look up aws_instance docs... encrypted = true is the argument name...
   aws_security_group uses ingress blocks with cidr_blocks..."
    │
    ▼
GENERATED TERRAFORM
  main.tf + variables.tf + outputs.tf + tests/ec2.tftest.hcl
    │
    ▼
TERRAFORM TEST (the contract)
  ✓ Instance type = t3.micro
  ✓ Root volume encrypted
  ✓ Only 443 from 0.0.0.0/0
  ✓ Tags present
  → ALL PASS
```

### The Complete Workflow — End to End

```
    ┌──────────┐
    │ ENGINEER │
    └────┬─────┘
         │
         │ writes prompt + test policy
         ▼
    ┌──────────────────────────────────────────────┐
    │              CLAUDE CODE                      │
    │                                               │
    │  1. Reads prompt                              │
    │  2. Skills shape HOW it will write            │
    │  3. Calls MCP for WHAT args to use            │
    │  4. Generates .tf files + .tftest.hcl         │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │           GENERATED FILES                     │
    │                                               │
    │  main.tf          ← infrastructure code       │
    │  variables.tf     ← parameterized inputs      │
    │  outputs.tf       ← downstream consumers      │
    │  tests/ec2.tftest.hcl  ← security contract    │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │           terraform test                      │
    │                                               │
    │  ✓ instance_type == "t3.micro"               │
    │  ✓ root_block_device.encrypted == true       │
    │  ✓ only 443 from 0.0.0.0/0                  │
    │  ✓ tags: ManagedBy, Environment, Team        │
    └──────────────────┬───────────────────────────┘
                       │
              ┌────────┴────────┐
              │                 │
         PASS ▼            FAIL ▼
    ┌──────────────┐   ┌──────────────────────────┐
    │  Ship it     │   │  Back to Kiro:            │
    │  (tf apply)  │   │  "Test failed. Fix the    │
    │              │   │   TF, not the test."       │
    └──────────────┘   └────────────┬──────────────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │ Kiro fixes    │
                            │ → rerun test  │
                            │ → loop until  │
                            │   green       │
                            └──────────────┘
```

**Remember:** MCP is the PIPE. Skills are the TEXTBOOKS. Tests are the CONTRACT.

---

## Where Each Piece Lives on Your Machine

```
Your machine
│
├── ~/demo-terraform-full/              ← project directory
│   ├── .kiro/
│   │   └── settings/
│   │       └── mcp.json               ← MCP server config lives HERE
│   │           {
│   │             "mcpServers": {
│   │               "terraform": {
│   │                 "command": "docker",
│   │                 "args": ["run", "-i", "--rm",
│   │                   "hashicorp/terraform-mcp-server"]
│   │               }
│   │             }
│   │           }
│   │
│   ├── main.tf                         ← generated by Kiro
│   ├── variables.tf                    ← generated by Kiro
│   ├── outputs.tf                      ← generated by Kiro
│   └── tests/
│       └── ec2.tftest.hcl             ← generated by Kiro
│
│
│   Skills installed via: npx skills add
│   (verify exact install location during dry-run)
│
└── (Docker)
    └── terraform-mcp-server            ← MCP server container
        Starts as child process when Kiro launches
        Connects via stdio (stdin/stdout)
        Dies when Kiro exits
```

---

## Quick Answers for Audience Questions

**"Can I use this with OpenAI/Gemini instead of Kiro?"**
MCP is an open standard. Any AI that supports MCP can use the Terraform MCP server.
Skills work across IDEs — `npx skills add` supports Kiro, Claude Code, Cursor, etc.

**"Does this work with Terraform Cloud / Enterprise?"**
Yes. The MCP server can connect to HCP Terraform / TFE with a token. It can read
workspace info, Sentinel policies, etc. Set `TFE_TOKEN` and `TFE_ADDRESS` env vars.

**"What about Pulumi / OpenTofu?"**
Anton's skill works with OpenTofu too. MCP server is Terraform-specific.
The testing + prompting patterns apply to any IaC tool.

**"Is this production-ready or just a demo?"**
The workflow is production-ready. Skills + MCP + tests in CI = real pipeline.
The specific prompts I showed are demo-simplified — in production you'd have
more detailed constraint prompts and more tests.

**"What about cost?"**
API costs apply. For a typical Terraform generation session: ~$0.10-0.30.
terraform test with mock providers: $0 (no AWS calls).
Infracost can estimate infrastructure cost before apply.

**"How is this different from Copilot writing Terraform?"**
Copilot autocompletes lines. This is an agent that reads registry docs, follows
expert skills, generates full modules, writes tests, and fixes failures. Different
category entirely.

---

## Prompting for Terraform — Why It's Different and How to Do It Right

This is the theory behind why the demo works. The talk is called "Prompting
Terraform" — you should be able to explain WHY certain prompts work better,
not just show it.

### Why Prompts Matter MORE for Infrastructure Than for App Code

Jab tum AI se Python function likhwaate ho aur wo galat likhta hai — what happens?
Unit test fails. You fix it. No harm done.

Jab tum AI se Terraform likhwaate ho aur wo galat likhta hai — what happens?
Port 22 open to the internet. Unencrypted database. Public S3 bucket.
**It deploys to production and creates a security incident.**

App code fails closed (error). Infrastructure fails OPEN (exposure).

That's why prompting for IaC is a different game. A lazy prompt for a Python
function costs you 10 minutes. A lazy prompt for Terraform can cost you a
breach.

### The Vague vs Constraint Prompt — The DIFF

This is the core visual of the whole demo. Same intent, two very different prompts:

```
VAGUE PROMPT (Act 1):
┌─────────────────────────────────────────────────────────┐
│ I need to deploy a small web application on AWS.        │
│ Set up the networking and compute. Keep it simple.      │
└─────────────────────────────────────────────────────────┘
                    ↓ AI fills ALL the gaps ↓
  • Which ports? → 22, 80 (most common, easiest)
  • Encryption? → No (you didn't ask)
  • Tags? → No (you didn't ask)
  • File structure? → One main.tf (simplest)
  • Variables? → Hardcoded (simplest)


CONSTRAINT PROMPT (what good looks like):
┌─────────────────────────────────────────────────────────┐
│ Generate ONLY an aws_security_group resource that:      │
│                                                         │
│ - Belongs to variable vpc_id                            │
│ - Allows ingress HTTPS (443) from 0.0.0.0/0            │
│ - Does NOT allow any other ingress from 0.0.0.0/0      │
│ - Has a description on every rule                       │
│ - Has tags Name, ManagedBy, Environment, Team           │
│                                                         │
│ If you cannot satisfy one of these constraints,         │
│ say so explicitly and explain which one.                │
└─────────────────────────────────────────────────────────┘
                    ↓ AI has no room to guess ↓
  • Which ports? → 443 only (you said so)
  • Other ports? → Blocked (you said "does NOT")
  • Tags? → Required (you listed them)
  • Scope? → One resource only (you said "ONLY")
  • Uncertainty? → Must flag it (you said "say so explicitly")
```

**The key insight:** The vague prompt isn't wrong. It's incomplete.
An LLM will ALWAYS fill gaps. The question is: do YOU fill the gaps,
or does the AI fill them with lazy defaults?

### Five Prompt Techniques for Terraform

These are concrete patterns you can use and teach:

**1. Negative Constraints — "Do NOT"**

LLMs are optimized to be helpful. They ADD things. "Do NOT" is the brake.

```
Bad:  "Create a security group for HTTPS"
      → AI might add SSH "for convenience"

Good: "Create a security group that allows HTTPS (443) from 0.0.0.0/0.
       Do NOT allow any other ingress from 0.0.0.0/0 on any port."
      → AI cannot add SSH without violating your rule
```

Hinglish: "LLM ko bolo kya karna hai, AND kya NAHI karna hai.
Sirf positive instructions doge toh wo extras add karega."

**2. Scope Control — "ONLY" / "Do not touch"**

Without scope, the AI rewrites everything. With scope, it's surgical.

```
Bad:  "Fix the security group"
      → AI might refactor your whole main.tf while it's at it

Good: "Fix ONLY the aws_security_group resource in main.tf.
       Do not modify any other resources or files."
      → AI knows the boundary
```

**3. Escalation Clause — "If you cannot, say so"**

This is the underrated one. When an AI can't do something, it usually
fakes it — generates plausible-looking but wrong code. The escalation
clause forces it to admit when it's stuck.

```
"If you cannot satisfy one of these constraints, say so explicitly
and explain which one."
```

Ye line add karo har constraint prompt mein. AI ko permission do
honestly bolne ke liye ki "I can't do this."

**4. Output Format Control**

Tell the AI what FILE STRUCTURE you want. Otherwise it dumps everything
into one file.

```
"Generate the following files:
- main.tf — VPC, subnet, security group, EC2 instance
- variables.tf — all input variables with type, description, and default
- outputs.tf — instance public IP, security group ID
- tests/ec2.tftest.hcl — test assertions for the rules above"
```

**5. Reference Real State — "for the current configuration"**

When you say "for the current configuration", Kiro reads your
existing .tf files before generating. This grounds the output in reality
instead of starting from scratch.

```
Bad:  "Write tests for an EC2 instance"
      → AI invents its own resource names

Good: "Write tests for the current configuration that enforce:
       1. root volume encrypted
       2. only HTTPS from 0.0.0.0/0"
      → AI reads your actual resource names and writes matching assertions
```

### The Four Layers — Prompts in Context

Prompts are just ONE layer. Here's how they stack:

```
┌──────────────────────────────────────────────────┐
│                  LAYER 4: TESTS                   │
│  terraform test enforces the contract             │
│  → Catches what ALL other layers miss             │
│  → "I don't care who wrote it. Pass or fail."     │
├──────────────────────────────────────────────────┤
│                  LAYER 3: PROMPTS                 │
│  Your specific request + constraints              │
│  → "What I want, what I don't want"              │
│  → This is YOUR input — changes every time        │
├──────────────────────────────────────────────────┤
│                  LAYER 2: SKILLS                  │
│  Best practices loaded at startup                 │
│  → "How to write good Terraform in general"       │
│  → Same for every prompt                          │
├──────────────────────────────────────────────────┤
│                  LAYER 1: MCP                     │
│  Live data from the registry                      │
│  → "What the correct argument names are right now"│
│  → Same for every prompt                          │
└──────────────────────────────────────────────────┘
```

**Layer 1 (MCP)** = correct data.
**Layer 2 (Skills)** = expert patterns.
**Layer 3 (Prompts)** = your specific intent + constraints.
**Layer 4 (Tests)** = enforcement. The final gate.

Without Layer 1, the AI hallucinates argument names.
Without Layer 2, the AI writes messy code that "works."
Without Layer 3, the AI guesses what you want.
Without Layer 4, you have no proof it's safe.

**The demo shows Layers 1+2 can compensate for a weak Layer 3** (same
vague prompt, better output). But the BEST result comes from all four.

### Prompt Anti-Patterns for Terraform

Things to AVOID (and why):

```
❌ "Make it production-ready"
   → Too vague. AI's definition of "production-ready" ≠ yours.
   → Instead: list the specific properties that make it production-ready.

❌ "Use best practices"
   → Which practices? Whose? From when?
   → Instead: that's what skills are for. Don't put "use best practices"
     in the prompt — load a skill that defines them.

❌ "Keep it simple" (without constraints)
   → AI interprets "simple" as "fewest lines of code"
   → Fewest lines = no variables, no encryption, no tags, no tests
   → Instead: "Keep the architecture simple (single instance, no ASG)
     but follow standard security and tagging practices."

❌ Telling the AI to do too much in one prompt
   → "Create a full VPC with subnets, NAT, ALB, ASG, RDS, S3, CloudFront,
     Route53, ACM, and WAF"
   → AI will hallucinate half the arguments.
   → Instead: build incrementally. One resource type at a time.
     Or use modules and ask for composition.
```

### How This Maps to the Demo

| Demo Moment | Prompt Technique Shown |
|------------|----------------------|
| Act 1 (naive) | Anti-pattern: vague prompt, no constraints, "keep it simple" |
| Act 3 (same prompt + tools) | Skills compensating for weak prompt (Layer 2 covers Layer 3) |
| Act 4 (write tests) | Output format control + reference real state + scope |
| Act 4 (fix failures) | Scope control ("do not change") + reference error output |
| Optional (constraint prompt) | Full constraint prompt: negative constraints, scope, escalation |
