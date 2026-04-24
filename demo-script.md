# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

> Duration: ~45 min | Format: 100% Live Demo, No Slides | Presenter: Sagar Utekar

---

## The Story

> "Can we safely let AI design, generate, and refactor Terraform **modules** that other teams will consume?"

Everything in this demo answers that question. Four steps, each adding one layer.

---

## Pre-Demo Terminal Setup

```bash
# Two directories ready:
# ~/demo-terraform-naive/     ← clean, NO skills, NO MCP (for Step 0)
# ~/demo-terraform-full/      ← has .claude/settings.json with MCP config (for Step 3)

# Neither directory has skills yet — we install them live in Steps 1 and 2.
# Font size: 20+ for camera. Dark theme.
```

---

## Opening — The Problem (2 min, on camera, NO terminal)

"Here is the thing everyone keeps saying: 'Just ask AI to write your Terraform.' And it works. It absolutely writes Terraform. The problem? It also writes Terraform that opens port 22 to the world, creates unencrypted S3 buckets, and ships `allow *` IAM policies — because the LLM's goal is to close the chat loop as fast as possible, not to satisfy your security policy.

So the question is: can we actually trust AI to write Terraform that other teams will consume? Not throwaway HCL. Real modules. With tests. With CI. With style.

I am going to show you that we can — but only if we give the AI three things it does not have by default:

1. **Best-practices knowledge** — so it knows how good Terraform should look.
2. **Product-specific expertise** — so it follows HashiCorp's own patterns, not random GitHub code.
3. **Live data** — so it reads real provider docs instead of guessing from training data.

And then we verify everything with `terraform test` — a contract that does not care whether a human or AI wrote the code.

Four steps. Each one adds a layer. Let's go."

---

## Step 0 — Baseline: Naive AI Terraform (5 min)

**Goal:** Establish the pain. Raw LLM + Terraform is dangerous by default.

**[OPEN Claude Code in ~/demo-terraform-naive/ — NO skills, NO MCP]**

```bash
cd ~/demo-terraform-naive/
claude
```

### Demo: The Naive Prompt

```
> Create a reusable Terraform module for an S3 bucket with versioning,
> a VPC with public and private subnets, and an EKS cluster.
> Include a testing strategy and a CI pipeline.
```

**[Let Claude generate. DON'T interrupt.]**

"Look at what it generated. It runs. It might even plan. But watch:"

**[Point out on screen — check for these common failures:]**

| What to look for | Typical naive output |
|-----------------|---------------------|
| S3 encryption | Missing or optional |
| S3 public access block | Missing entirely |
| VPC flow logs | Missing |
| EKS endpoint | Public by default |
| EKS secrets encryption | Missing |
| File structure | Single main.tf or messy layout |
| Variables | Hardcoded values |
| Tags | Missing or inconsistent |
| Tests | None, or a vague mention of Terratest |
| CI pipeline | Basic or missing security scanning |
| IAM policies | `Action: "*"` to avoid errors |

"The AI did exactly what I asked. The problem is everything I DIDN'T ask. It took the path of least resistance — a single file, default VPC, allow-all policies, no tests, no CI. You feel like a 10x engineer, but you are automating the creation of technical debt."

**[KEY LINE]:** "This is the gap between 'code that runs' and 'code that other teams can safely consume.' We are going to close it — one layer at a time."

**[Exit Claude Code: Ctrl+C]**

---

## Step 1 — Add Anton's Terraform Skill: The Best-Practices Brain (12 min)

**Goal:** Show what a general best-practices skill buys you. Same prompt, dramatically different output.

**[ON CAMERA]**

"Step one: we give the AI a brain. Not a generic LLM brain — a Terraform-specific brain. This comes from Anton Babenko, the person whose Terraform modules have been downloaded hundreds of millions of times. He packaged his expertise into something called a Skill."

### What is a Skill?

"Quick context: Agent Skills are an open standard from Anthropic for packaging domain expertise into portable instructions that AI agents load on demand. A skill is a folder of curated instructions and reference materials. When you load a skill, the AI gains expert-level context. Think of it as giving the AI a textbook before an exam."

### Install Live

```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
```

"That is it. One clone. Now let me show you what is inside:"

```bash
ls ~/.claude/skills/terraform/
```

"Anton's skill is a four-pillar framework:"

```
┌─────────────────┬───────────────────────────────────────────┐
│ THE ENGINE      │ Strict loop: init → validate → plan       │
│                 │ State file = source of truth               │
│                 │ Auto-format on every generation            │
├─────────────────┼───────────────────────────────────────────┤
│ THE GUARDRAILS  │ Modularity by default — no monoliths      │
│                 │ Naming conventions + tagging strategies    │
├─────────────────┼───────────────────────────────────────────┤
│ THE EXPERT      │ Nested for_each, dynamic blocks           │
│                 │ Anti-hallucination: forces real docs       │
├─────────────────┼───────────────────────────────────────────┤
│ THE STACK       │ Integrates tflint, tfsec, infracost       │
│                 │ Security + cost baked into generation      │
└─────────────────┴───────────────────────────────────────────┘
```

### Demo: Same Prompt, With Anton's Skill Active

```bash
cd ~/demo-terraform-naive/
claude
```

```
> Create a reusable Terraform module for an S3 bucket.
>
> Requirements:
> - Proper module layout (main/variables/outputs, examples directory).
> - Native terraform test files: at least one plan-based check with mock
>   provider and one apply-based integration test.
> - GitHub Actions workflow that runs fmt, validate, tflint, security scan,
>   terraform test, and optionally Infracost.
```

**[Let Claude generate with the skill active. Watch for:]**

- Clean `modules/s3/` directory with `main.tf`, `variables.tf`, `outputs.tf`
- An `examples/` directory with a working example
- `.tftest.hcl` files — unit (mocked) AND integration (real AWS)
- A non-trivial GitHub Actions workflow with tflint, Checkov/tfsec, cost estimation
- Encryption enabled by default, not as an option
- `coalesce()` or similar for null-safe outputs
- Proper variable descriptions and types

**[Side-by-side with Step 0:]**

```
STEP 0 (Naive)                   │  STEP 1 (Anton's Skill)
─────────────────────────────────┼──────────────────────────────────
Single file dump                 │  modules/s3/{main,variables,outputs}.tf
No examples                      │  examples/ directory with working usage
No tests                         │  .tftest.hcl: unit (mock) + integration
No CI                            │  GitHub Actions: fmt/validate/tflint/tfsec
Encryption optional or missing   │  Encryption ON by default
Hardcoded values                 │  Variables with types + descriptions
No cost awareness                │  Infracost in CI pipeline
```

**[OPTIONAL: Run terraform test now to show tests execute]**

```bash
cd modules/s3/
terraform init
terraform test
```

**[KEY LINE]:** "Turn on this one skill and the AI stops writing throwaway HCL. It writes something close to what an experienced Terraform practitioner would. But it is still using community patterns — not HashiCorp's own. For that, we need the next layer."

---

## Step 2 — Layer HashiCorp Agent Skills: Product-Specific Expertise (12 min)

**Goal:** Show how HashiCorp's official Skills refine and specialize what Anton's skill started.

**[ON CAMERA]**

"Anton's skill gives broad Terraform best practices — testing, modules, CI, security. But HashiCorp themselves released official Agent Skills in February 2026. These encode how HashiCorp thinks their tools should be used. Style conventions, Terraform Stacks patterns, provider development guidelines, Packer image building — it comes straight from the source."

### Install Live

```bash
# Inside Claude Code:
> /plugin marketplace add hashicorp/agent-skills
```

Or from terminal:

```bash
npx skills add hashicorp/agent-skills
```

"What is in the HashiCorp Agent Skills pack?"

**[List them:]**

```
┌──────────────────────────────┬──────────────────────────────────────────────┐
│ Terraform Style Guide        │ HashiCorp's documented naming, formatting,   │
│                              │ tagging, file layout conventions             │
├──────────────────────────────┼──────────────────────────────────────────────┤
│ Write & Run Terraform Tests  │ Knows .tftest.hcl syntax, mock providers,   │
│                              │ unit vs integration test patterns           │
├──────────────────────────────┼──────────────────────────────────────────────┤
│ Terraform Stacks             │ Multi-env, multi-region orchestration with  │
│                              │ HCP Terraform / Terraform Enterprise        │
├──────────────────────────────┼──────────────────────────────────────────────┤
│ Provider Development         │ Plugin framework, schema design, lifecycle  │
│                              │ methods, resource testing patterns          │
├──────────────────────────────┼──────────────────────────────────────────────┤
│ Module Refactoring           │ Break monolithic configs into clean modules │
├──────────────────────────────┼──────────────────────────────────────────────┤
│ Packer Skills                │ AWS, Azure, Windows image building with     │
│                              │ HCP Packer integration                     │
└──────────────────────────────┴──────────────────────────────────────────────┘
```

"The key distinction: Anton's skill says 'here is how good Terraform looks.' HashiCorp's skills say 'here is how WE think you should use Terraform.' Both matter."

### Demo: Refine With HashiCorp's Skills

"I am going to take the module we just generated with Anton's skill and run it through HashiCorp's style guide and refactor skills."

```
> Using the HashiCorp Terraform style guide and refactor skills:
>
> 1. Review the S3 module we just created for HashiCorp-style conventions.
> 2. Refactor anything that doesn't follow the documented style:
>    naming, file structure, tagging strategy, variable conventions.
> 3. Show me what changed and why.
> 4. If this module could benefit from Terraform Stacks for multi-environment
>    deployment, show what a Stacks component would look like.
```

**[Let Claude refine the code. Watch for:]**

- Naming changes to match official style guide
- Variable ordering / grouping aligned with HashiCorp conventions
- Tags strategy refined (maybe `default_tags` on provider)
- File structure adjustments
- Possibly a Terraform Stacks scaffold (`component.tfstack.hcl`)
- Commentary that references HashiCorp's documented conventions

**[Point out the differences:]**

"See what happened? The module was already good from Anton's skill. But now:"
- Variable names follow HashiCorp's naming convention, not community convention
- Tagging uses `default_tags` on the provider block (HashiCorp's recommended approach)
- File layout matches what HashiCorp documents, not what is most common on GitHub
- If Stacks appeared — that is something only the HashiCorp skill knows about

**[KEY LINE]:** "Anton's skill gives broad best practices. HashiCorp's skills align that with the vendor's own recommended way of using Terraform. Together, the AI knows HOW good Terraform should look AND how HashiCorp specifically recommends building it. But it is still working from training data. For the last layer, we need live data."

---

## Step 3 — Terraform MCP Server: Live Data + terraform test (12 min)

**Goal:** The AI stops guessing. Then we verify everything with a contract.

**[ON CAMERA]**

"Skills are textbooks. But textbooks go out of date. Provider versions change. Module interfaces change. New arguments get added. The AI's training data is frozen. So for the final layer, we add a live data pipe: the Terraform MCP server."

### Show the MCP Config

```bash
cd ~/demo-terraform-full/
cat .claude/settings.json
```

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

"MCP — Model Context Protocol — is the pipe that connects live data to the AI. The Terraform MCP server gives the AI tools to:

- **Read current provider and module docs** from the Terraform Registry
- **Discover module inputs, outputs, and versions** — no guessing
- **Access HCP Terraform / TFE workspace info** if connected

Skills are the textbooks. MCP is the pipe to real-time data. They are complementary."

### Demo: Force Registry Lookups

```bash
claude
```

```
> Using the Terraform MCP server, design a module that wraps the official
> AWS VPC and EKS modules.
>
> Rules:
> - First, discover their latest versions and input schemas from the
>   public Terraform Registry. Do not guess argument names.
> - Generate a thin 'platform' module that composes VPC + EKS with:
>   encrypted flow logs, private EKS endpoint, KMS-encrypted secrets,
>   and opinionated tagging (ManagedBy, Environment, Team).
> - Include terraform test files that verify:
>   1. EKS endpoint is private (public access = false)
>   2. VPC flow logs are enabled
>   3. S3 state bucket (if any) blocks all public access
>   4. KMS key rotation is enabled
>   5. No security group allows 0.0.0.0/0 on non-443 ports
> - Use mock_provider so tests run without AWS credentials.
```

**[Let Claude work. Watch for MCP tool calls:]**

"See that? It is calling the MCP server to look up the actual VPC module documentation. It is reading the real input variables — `enable_flow_log`, `create_flow_log_cloudwatch_log_group` — not hallucinating them from training data. Now it is looking up the EKS module. It sees `cluster_endpoint_public_access`, `cluster_encryption_config` — the actual argument names from the current version."

**[Point out in the generated code:]**
- Correct `source` paths with pinned versions (not guessed)
- Argument names match real module interfaces (not hallucinated)
- Version numbers are current, not from 2024 training data

### Demo: Run terraform test — The Contract

```bash
terraform init
terraform test
```

**[If tests PASS]:** "All five tests pass. The AI generated the code, the skills shaped it, the MCP server gave it real data, and `terraform test` verified the contract. No human reviewed 500 lines of HCL. A human wrote the TEST — five security policies — and the test did the rest."

**[If tests FAIL — even better for the demo]:**

"See that? Test 3 failed — the S3 bucket public access block is missing. The AI missed it. This is EXACTLY why you do not skip tests just because AI wrote the code. Let me fix it:"

```
> The terraform test failed: S3 bucket must block all public access.
> Fix the Terraform to satisfy this test. Do NOT modify the test file.
```

**[Let Claude fix it, then re-run:]**

```bash
terraform test
```

"Now it passes. The loop is: AI generates → tests catch → AI fixes → tests verify. The human reviews the TEST, not the Terraform."

### Explain the Mock Provider

"Quick note: these tests ran in two seconds with zero AWS credentials. Terraform test supports mock providers — you get fake values for resources and data sources, so your tests validate the CONFIGURATION, not live infrastructure. Zero cost. Zero risk. Fast CI."

**[KEY LINE]:** "Skills define HOW we want Terraform to look. MCP gives CORRECT DATA about providers and modules. `terraform test` enforces a CONTRACT on anything AI or humans generate. Three layers. One workflow."

---

## Closing (2 min, on camera)

"Let me bring it all together. We went through four steps:"

```
STEP 0: Naked LLM
  └─ "Code that runs but shouldn't ship"

STEP 1: + Anton's Terraform Skill
  └─ "Code that follows community best practices"

STEP 2: + HashiCorp Agent Skills
  └─ "Code that follows HashiCorp's own recommended patterns"

STEP 3: + Terraform MCP Server + terraform test
  └─ "Code built from real data, verified by a contract"
```

"Three layers, each with a clear role:"

```
┌─────────────────────────────────────────────────────────┐
│  terraform test             ← THE CONTRACT              │
│  Catches what all three layers missed.                  │
├─────────────────────────────────────────────────────────┤
│  Terraform MCP Server       ← THE DATA PIPE             │
│  Real-time registry docs, module schemas, versions.     │
│  AI stops guessing, starts reading.                     │
├─────────────────────────────────────────────────────────┤
│  HashiCorp Agent Skills     ← THE PRODUCT TEXTBOOK      │
│  Style guide, Stacks, provider dev, Packer.             │
│  How HashiCorp thinks you should use their tools.       │
├─────────────────────────────────────────────────────────┤
│  Anton's Terraform Skill    ← THE PRACTICES TEXTBOOK    │
│  Testing, modules, CI/CD, security, DO vs DON'T.        │
│  How experienced practitioners write Terraform.         │
├─────────────────────────────────────────────────────────┤
│  LLM (Claude)               ← THE ENGINE                │
└─────────────────────────────────────────────────────────┘
```

"The answer to our question — can we safely let AI write Terraform modules that other teams consume? — is YES. But only with all three layers:

1. **Anton's skill** teaches the AI how good Terraform looks — across any cloud, any provider.
2. **HashiCorp's skills** align that with how HashiCorp specifically recommends using their tools.
3. **The MCP server** connects the AI to live data so it stops guessing at module interfaces.
4. **`terraform test`** is the final contract — it does not care who wrote the code.

The future is not 'AI writes Terraform and you pray.' The future is: AI writes with expert knowledge, reads live docs, and has to pass your tests before anything hits `apply`.

All the code, test files, and configurations from this demo are in the repo. Links below.

Thank you."

---

## Links to Share

- Anton Babenko's Terraform Skill: https://github.com/antonbabenko/terraform-skill
- HashiCorp Agent Skills: https://github.com/hashicorp/agent-skills
- Terraform MCP Server: https://github.com/hashicorp/terraform-mcp-server
- Terraform Test Docs: https://developer.hashicorp.com/terraform/language/tests
- HashiCorp Blog Post: https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills

---

## Backup Demos (If Time or Q&A)

### Backup 1: Skill vs No-Skill Side-by-Side

If someone asks "do skills actually matter?":

```
# Same prompt, two runs:
# Run 1: temporarily move skills away
mv ~/.claude/skills ~/.claude/skills.bak
# Run prompt, save output

# Run 2: restore skills
mv ~/.claude/skills.bak ~/.claude/skills
# Run same prompt, compare
```

| Feature              | No Skill           | With Skills                     |
|----------------------|--------------------|---------------------------------|
| Configurability      | Hardcoded blocks   | Fully variable-driven           |
| Structure            | Tests separate     | Tests inside module (HashiCorp) |
| Testing              | Single file        | Unit (mocked) + Integration     |
| CI/CD                | Basic YAML         | tflint + tfsec + infracost      |
| Null safety          | May fail on empty  | coalesce() for safe outputs     |
| Security             | Encryption toggle  | Encryption ON by default        |

### Backup 2: Packer Skill

If audience is interested beyond Terraform:

```
> Using the Packer skills, create an HCL template that builds an Ubuntu 24.04
> AMI with Docker pre-installed. Use the amazon-ebs builder.
> Include proper tagging and HCP Packer integration for image tracking.
```

### Backup 3: Module Refactoring Skill

For the "I have a monolith" question:

```
> I have a single main.tf with 300+ lines — VPC, EKS, RDS, and S3 all in one file.
> Use the module refactoring skill to break this into separate modules under modules/.
> Keep the root module as a thin orchestration layer.
```

### Backup 4: Provider Development Skill

If audience includes provider authors:

```
> I want to build a Terraform provider for our internal API.
> Using the provider development skill, scaffold the initial provider structure:
> - Provider schema with authentication config
> - One resource (team_member) with CRUD lifecycle
> - Acceptance tests for the resource
> Follow the Terraform plugin framework, not the legacy SDK.
```

### Backup 5: The Constraint Prompt Pattern

Show prompting technique independent of skills:

```
> Generate a Terraform aws_security_group resource.
>
> CONSTRAINTS:
> - NO ingress rules with cidr_blocks = ["0.0.0.0/0"] except port 443
> - All egress must go through a prefix list, not open CIDR
> - Must include description on every rule
> - Resource must have: Name, Environment, Team, and ManagedBy tags
>
> If you cannot satisfy a constraint, say so. Do not silently skip it.
```

"That last line is critical. Without it, the LLM quietly drops constraints it finds inconvenient."
