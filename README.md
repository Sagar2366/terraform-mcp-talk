# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

100% live demo. No slides. All Terraform is generated on stage by Kiro.

## What this repo contains

- **prompts.md** — copy-paste-ready prompts for every demo act, with security guardrails

That's it. Everything else — Terraform configs, tests, `.gitignore` — is generated live during the demo from the prompts.

## The three layers

1. **Terraform MCP Server** — live registry / HCP data so the AI reads current docs instead of guessing.
2. **HashiCorp Agent Skills** — official product-specific patterns (style guide, Stacks, provider dev, Packer).
3. **Anton Babenko's Terraform Skill** — community best-practices for modules, testing, CI/CD.

Plus **`terraform test`** as the contract that catches anything the AI misses.

## Demo flow

| Act  | What happens                               | Tools active       |
|------|--------------------------------------------|--------------------|
| Act 1 | Naive prompt — insecure output            | None               |
| Act 2 | Install skills + verify MCP tools         | Skills + MCP load  |
| Act 3 | Same prompt + constraints — safer output  | Skills + MCP active|
| Act 4 | Write tests, run them, fix failures       | Skills + MCP active|

No AWS credentials needed — the core demo uses `terraform plan` + `mock_provider` only.

Optional bonus content (CI/CD pipeline, real AWS apply) is in `prompts.md`.

## Prerequisites

- Terraform >= **1.6** (>= 1.7 for mocks)
- Node.js >= **18**
- Docker
- Kiro (Desktop from [kiro.dev](https://kiro.dev/downloads) or CLI)

See **prompts.md** for setup commands and all demo prompts.

## Links

- [Anton Babenko's Terraform Skill](https://github.com/antonbabenko/terraform-skill)
- [HashiCorp Agent Skills](https://github.com/hashicorp/agent-skills)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Terraform Test Docs](https://developer.hashicorp.com/terraform/language/tests)
- [HashiCorp Blog: Introducing Agent Skills](https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills)
