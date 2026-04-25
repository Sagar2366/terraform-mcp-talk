# Prompting Terraform: Safely Using AI and the Terraform MCP Server for IaC

100% live demo. No slides. All Terraform is generated on stage by Kiro.

## What this repo contains

- **prompts.md** — copy-paste-ready prompts for each demo act, with security guardrails
- **preflight-checklist.md** — full machine setup: Kiro (Desktop + CLI), Terraform MCP server (Docker), AWS account, skills installation, dry-run steps

## What this repo does NOT contain

No speaker script. No slides. No Terraform code. Everything is generated live during the demo from the prompts.

## The three layers

1. **Anton Babenko's Terraform Skill** — community best-practices for modules, testing, CI/CD
2. **HashiCorp Agent Skills** — official product-specific patterns (style guide, Stacks, provider dev, Packer)
3. **Terraform MCP Server** — live registry data so the AI reads docs instead of guessing

Plus **`terraform test`** as the contract that catches anything the AI misses.

## Quick start (on the demo machine)

```bash
# 1. Install Terraform >= 1.6
terraform version

# 2. Set up Kiro
# Download Kiro Desktop from https://kiro.dev/downloads
# Or install CLI — check https://kiro.dev/docs/cli/getting-started

# 3. Set up MCP server
docker pull hashicorp/terraform-mcp-server

# 4. Configure AWS credentials (env vars — no files to leak)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
aws sts get-caller-identity

# 5. Create demo dirs
mkdir -p ~/demo-terraform-naive/
mkdir -p ~/demo-terraform-full/.kiro/settings/
# Copy MCP config into ~/demo-terraform-full/.kiro/settings/mcp.json
# See preflight-checklist.md for the full config

# 6. Skills are installed LIVE during the demo
```

## CI/CD

GitHub Actions pipeline — validates generated Terraform, then deploys with human approval:

```
Validate MCP Server ──┐
                      ├──→ Terraform Validate ──→ [Approve] ──→ Apply ──→ [Approve] ──→ Destroy
Validate Skills ──────┘     (fmt/init/validate/test)
```

| Job | What it does |
|-----|-------------|
| **Validate MCP Server** | Pulls Docker image, verifies JSON-RPC response |
| **Validate Skills** | Installs both skills, verifies SKILL.md files exist |
| **Terraform Validate** | `fmt -check`, `init`, `validate`, `test` on `infra/` |
| **Terraform Apply** | Requires manual approval (`production` environment), then applies |
| **Terraform Destroy** | Requires manual approval, then destroys all resources |

### Setup

1. **AWS secrets** — Go to **Settings → Secrets → Actions** and add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
2. **Environment** — Go to **Settings → Environments**, create `production`, add yourself as required reviewer

### Workflow

1. Generate Terraform from prompts using Kiro
2. Commit the generated `.tf` files to `infra/`
3. Push — CI validates automatically
4. Review the plan, approve in GitHub to apply
5. Approve again to destroy after demo

## Links

- [Anton Babenko's Terraform Skill](https://github.com/antonbabenko/terraform-skill)
- [HashiCorp Agent Skills](https://github.com/hashicorp/agent-skills)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Terraform Test Docs](https://developer.hashicorp.com/terraform/language/tests)
- [HashiCorp Blog: Introducing Agent Skills](https://www.hashicorp.com/en/blog/introducing-hashicorp-agent-skills)
