# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

100% live demo. No slides. All Terraform is generated on stage by Kiro.

## What this repo contains

- **demo-script.md** — talk script, flow (~40-45 min), and personal theory notes at the bottom
- **prompts.md** — copy-paste-ready prompts for each demo step
- **preflight-checklist.md** — full machine setup: Kiro (Desktop + CLI), Terraform MCP server (Docker), skills installation, dry-run steps

## What this repo does NOT contain

No `main.tf`. No `variables.tf`. No `.tftest.hcl`. All code is generated live during the demo.

The `sample-config/` directory contains a "golden" reference config (what Act 3 should produce) used by CI to validate `terraform fmt`, `terraform validate`, and `terraform test`. The `sample-config-naive/` directory contains an intentionally insecure config (what Act 1 produces) — CI proves the tests **fail** against it.

## The three layers

1. **Anton Babenko's Terraform Skill** — community best-practices for modules, testing, CI/CD
2. **HashiCorp Agent Skills** — official product-specific patterns (style guide, Stacks, provider dev, Packer)
3. **Terraform MCP Server** — live registry data so the AI reads docs instead of guessing

Plus **`terraform test`** as the contract that catches anything the AI misses.

## Quick start (on the demo machine)

```bash
# 1. Install Terraform >= 1.6
terraform version

# 2. Set up Kiro (pick one)
# Download Kiro Desktop from https://kiro.dev/downloads
# Or install CLI — check https://kiro.dev/docs/cli/getting-started

# 3. Set up MCP server
docker pull hashicorp/terraform-mcp-server

# 4. Create demo dirs
mkdir -p ~/demo-terraform-naive/
mkdir -p ~/demo-terraform-full/.kiro/settings/
# Copy MCP config into ~/demo-terraform-full/.kiro/settings/mcp.json
# See preflight-checklist.md for the full config

# 5. Skills are installed LIVE during the demo
```

## CI/CD

GitHub Actions runs on every push to `main`:

| Job | What it checks |
|-----|----------------|
| **Validate MCP Server** | Pulls Docker image, sends JSON-RPC initialize, verifies response |
| **Validate Skills** | `npx skills add` for both Anton's and HashiCorp's skills |
| **Validate Naive Config** | `terraform fmt/validate` on `sample-config-naive/`, tests must **FAIL** (proves insecure defaults) |
| **Validate Full Config** | `terraform fmt/validate/test` on `sample-config/`, tests must **PASS** (proves guardrails work) |

## Links

- [Anton Babenko's Terraform Skill](https://github.com/antonbabenko/terraform-skill)
- [HashiCorp Agent Skills](https://github.com/hashicorp/agent-skills)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Terraform Test Docs](https://developer.hashicorp.com/terraform/language/tests)
- [HashiCorp Blog: Introducing Agent Skills](https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills)
