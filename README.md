# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

100% live demo. No slides. All Terraform is generated on stage by Claude Code.

## What this repo contains

- **demo-script.md** — talk script and flow (~40-45 min)
- **prompts.md** — copy-paste-ready prompts for each demo step
- **preflight-checklist.md** — full machine setup: Claude Code (VSCode + CLI), Terraform MCP server (npx or Docker), skills installation, dry-run steps

## What this repo does NOT contain

No `main.tf`. No `variables.tf`. No `.tftest.hcl`. All code is generated live during the demo.

## The three layers

1. **Anton Babenko's Terraform Skill** — community best-practices for modules, testing, CI/CD
2. **HashiCorp Agent Skills** — official product-specific patterns (style guide, Stacks, provider dev, Packer)
3. **Terraform MCP Server** — live registry data so the AI reads docs instead of guessing

Plus **`terraform test`** as the contract that catches anything the AI misses.

## Quick start (on the demo machine)

```bash
# 1. Install Terraform >= 1.6
terraform version

# 2. Set up Claude Code (pick one)
code --install-extension anthropic.claude-code   # VSCode extension
npm install -g @anthropic-ai/claude-code         # CLI

# 3. Set up MCP server (pick one)
npx -y terraform-mcp-server --help               # npx
docker pull hashicorp/terraform-mcp-server       # Docker

# 4. Create demo dirs
mkdir -p ~/demo-terraform-naive/
mkdir -p ~/demo-terraform-full/.claude/
# Copy MCP config into ~/demo-terraform-full/.claude/settings.json
# See preflight-checklist.md for the full config

# 5. Skills are installed LIVE during the demo
```

## Links

- [Anton Babenko's Terraform Skill](https://github.com/antonbabenko/terraform-skill)
- [HashiCorp Agent Skills](https://github.com/hashicorp/agent-skills)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Terraform Test Docs](https://developer.hashicorp.com/terraform/language/tests)
- [HashiCorp Blog: Introducing Agent Skills](https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills)
