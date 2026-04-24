# Theory Cheat Sheet — For Sagar's Eyes Only

This is NOT for the audience. This is so YOU have the concepts crystal clear
before you go on stage. Read it once, internalize it, then explain it in your
own words during the demo.

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
│  During code generation, Claude calls MCP tools:                        │
│  "I need to look up aws_instance docs before writing..."                │
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

Socho ek situation. Tum Claude se bolo "AWS VPC module use kar ke Terraform likh do."
Claude kya karega? Apne training data se likhega. Training data kab ka hai? 6 months
purana. 1 saal purana. Module ka version change ho gaya. Arguments change ho gaye.
Naye arguments aaye. Claude ko pata hi nahi.

Yahi problem MCP solve karta hai.

MCP ek open standard hai — Anthropic ne banaya — jo AI models ko real-time data
sources se connect karta hai. Ek protocol hai, jaise HTTP web ke liye hai, waise
MCP AI tools ke liye hai.

```
Without MCP:
  You ask Claude → Claude guesses from training data → Maybe correct, maybe hallucinated

With MCP:
  You ask Claude → Claude calls MCP server → MCP reads LIVE docs from registry.terraform.io
  → Claude gets real argument names, types, defaults → Generates correct code
```

**How it works technically:**

1. You configure an MCP server in `.claude/settings.json`
2. When Claude Code starts, it connects to that server via stdio (stdin/stdout)
3. The server exposes "tools" — functions the AI can call
4. Claude decides WHEN to call which tool based on your prompt
5. The tool returns real data — Claude uses that data to generate code

### MCP Protocol — How the Pipe Works

```
┌──────────────┐          stdio (stdin/stdout)         ┌──────────────────┐
│              │  ──────── JSON-RPC messages ────────▶  │                  │
│  Claude Code │                                        │  MCP Server      │
│  (MCP Client)│  ◀──────── tool results ────────────  │  (terraform-mcp) │
│              │                                        │                  │
└──────────────┘                                        └──────────────────┘

Step-by-step during generation:

1. Claude reads your prompt
   "...deploy a small web app on AWS..."

2. Claude (guided by skills) decides it needs resource docs
   → Calls MCP tool: get_provider_details("hashicorp/aws")

3. MCP server receives the call
   → Hits registry.terraform.io for current provider docs

4. MCP server returns real documentation
   ← Actual argument names, types, required fields, defaults

5. Claude uses REAL argument names to generate Terraform
   → No hallucination. No guessing. Real data.
```

> The official MCP architecture follows a Host → Client → Server model.
> Claude Code is the Host, it creates MCP Clients (one per server),
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

Jab tum skill load karte ho, Claude ke context window mein ye sab inject
ho jata hai. Ab Claude sirf apne training data se nahi likh raha — wo ek
expert ki guidance follow kar raha hai.

### How Skills Load — Architecture

**Verified from GitHub repos (Apr 2026):**

```
~/.claude/skills/                        Claude Code context window
├── terraform/        ──── loaded ────▶  ┌─────────────────────────┐
│   └── SKILL.md               at        │                         │
│      (Anton Babenko's        startup   │  System prompt          │
│       community skill)                 │  + Anton's skill rules  │
│                                        │  + HashiCorp skill rules│
│                                        │  + Your prompt          │
│                                        │                         │
(HashiCorp Agent Skills:                 │  "When writing TF:      │
 installed via plugin)                   │   - always use modules  │
                                         │   - encrypt by default  │
agent-skills/         ──── loaded ────▶  │   - write tests         │
├── terraform/                 at        │   - follow HC style     │
│   ├── code-generation/       startup   │   - use default_tags    │
│   │   └── skills/                      │   - run tflint/tfsec"   │
│   │       ├── terraform-               │                         │
│   │       │   style-guide/             └─────────────────────────┘
│   │       │   └── SKILL.md                       │
│   │       └── write-run-              Claude uses these rules
│   │           tests/                  while generating code
│   │           └── SKILL.md                       │
│   ├── module-generation/                         ▼
│   │   └── skills/              ┌─────────────────────────┐
│   │       └── .../             │  Generated Terraform     │
│   └── provider-development/    │  that follows ALL        │
│       └── skills/              │  loaded skill rules      │
│           └── .../             └─────────────────────────┘
└── packer/
    └── .../

Key insight:
  Skills are NOT code. Skills are INSTRUCTIONS.
  They don't execute. They guide.
  Like a style guide pinned above your desk — you read it, then write code.
```

Structure verified from: `github.com/hashicorp/agent-skills` README

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

Install: `git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform`

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
# Option 1: npx skills
npx skills add hashicorp/agent-skills

# Option 2: Claude Code plugin
claude plugin marketplace add hashicorp/agent-skills
claude plugin install terraform-code-generation@hashicorp
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
SKILLS (loaded into Claude's context)
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
    │  Ship it     │   │  Back to Claude:          │
    │  (tf apply)  │   │  "Test failed. Fix the    │
    │              │   │   TF, not the test."       │
    └──────────────┘   └────────────┬──────────────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │ Claude fixes  │
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
│   ├── .claude/
│   │   └── settings.json              ← MCP server config lives HERE
│   │       {
│   │         "mcpServers": {
│   │           "terraform": {
│   │             "command": "npx",
│   │             "args": ["-y", "terraform-mcp-server"]
│   │           }
│   │         }
│   │       }
│   │
│   ├── main.tf                         ← generated by Claude
│   ├── variables.tf                    ← generated by Claude
│   ├── outputs.tf                      ← generated by Claude
│   └── tests/
│       └── ec2.tftest.hcl             ← generated by Claude
│
├── ~/.claude/
│   └── skills/                         ← ALL skills live HERE
│       └── terraform/                  ← Anton Babenko's skill
│           └── SKILL.md                  (git clone)
│
│   HashiCorp Agent Skills installed via:
│   claude plugin marketplace add hashicorp/agent-skills
│   claude plugin install terraform-code-generation@hashicorp
│   (or: npx skills add hashicorp/agent-skills)
│
└── (npx cache or Docker)
    └── terraform-mcp-server            ← MCP server binary
        Starts as child process when Claude Code launches
        Connects via stdio (stdin/stdout)
        Dies when Claude Code exits
```

---

## Quick Answers for Audience Questions

**"Can I use this with OpenAI/Gemini instead of Claude?"**
MCP is an open standard. Any AI that supports MCP can use the Terraform MCP server.
Skills are currently most mature for Claude Code, but the format is open too.

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
Claude API costs apply. For a typical Terraform generation session: ~$0.10-0.30.
terraform test with mock providers: $0 (no AWS calls).
Infracost can estimate infrastructure cost before apply.

**"How is this different from Copilot writing Terraform?"**
Copilot autocompletes lines. This is an agent that reads registry docs, follows
expert skills, generates full modules, writes tests, and fixes failures. Different
category entirely.

---

## Official References

- MCP Protocol: https://modelcontextprotocol.io/introduction
- MCP Architecture: https://modelcontextprotocol.io/docs/concepts/architecture
- Terraform MCP Server: https://github.com/hashicorp/terraform-mcp-server
- HashiCorp Agent Skills: https://github.com/hashicorp/agent-skills
- Anton's Terraform Skill: https://github.com/antonbabenko/terraform-skill
- Terraform Test Docs: https://developer.hashicorp.com/terraform/language/tests
- HashiCorp Blog: https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills
