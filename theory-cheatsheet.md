# Theory Cheat Sheet — For Sagar's Eyes Only

This is NOT for the audience. This is so YOU have the concepts crystal clear
before you go on stage. Read it once, internalize it, then explain it in your
own words during the demo.

---

## What is MCP? (Model Context Protocol)

**The one-liner:** MCP is a USB port for AI — plug in any data source and the
AI can read from it.

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

```
Claude Code ←→ MCP Server (terraform-mcp-server) ←→ Terraform Registry API
   (AI)           (middleware)                          (real data)
```

**Terraform MCP server specifically gives these tools:**

- Registry docs lookup — read provider/module documentation live
- Module input/output discovery — know exact variable names and types
- Provider resource docs — real argument names, not guessed ones

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

**Remember:** MCP is the PIPE. Skills are the TEXTBOOKS. Tests are the CONTRACT.

---

## Quick Answers for Audience Questions

**"Can I use this with OpenAI/Gemini instead of Claude?"**
MCP is an open standard. Any AI that supports MCP can use the Terraform MCP server.
Skills are currently most mature for Claude Code, but the format is open too.

**"Does this work with Terraform Cloud / Enterprise?"**
Yes. The MCP server can connect to HCP Terraform / TFE with a token. It can read
workspace info, Sentinel policies, etc.

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
