# Pre-Flight Checklist — Demo Machine Setup

Run through this the night before or morning of. Takes ~20 min.

---

## 1. Install Claude Code for VSCode

### Option A: VSCode Extension (recommended for demo)

```bash
# Open VSCode, go to Extensions (Cmd+Shift+X)
# Search: "Claude Code"
# Install the Anthropic extension
# Or from terminal:
code --install-extension anthropic.claude-code
```

After install:
- Open VSCode
- You should see a Claude icon in the left sidebar (or open the Claude panel via Cmd+Shift+P → "Claude: Open")
- Sign in with your Anthropic account or API key
- Verify it works: type a message like "Hello" in the Claude panel

### Option B: CLI (for terminal-based demo)

```bash
# If you prefer the terminal version:
npm install -g @anthropic-ai/claude-code
# Or:
brew install claude-code

# Verify:
claude --version
```

### Which to use for the demo?

- **VSCode extension** — better for showing generated files side by side (editor + Claude panel)
- **CLI in terminal** — better for "pure terminal" look, easier for audience to follow

Pick one and stick with it. Don't switch mid-demo.

---

## 2. Software Versions

```bash
terraform version        # Need >= 1.6 (ideally 1.9+) for terraform test
node --version           # Need v18+ for npx
git --version            # Need for cloning Anton's skill
docker --version         # Need if using Docker-based MCP server
```

---

## 3. Set Up the Terraform MCP Server

You have two options. Pick one.

### Option A: npx (simpler, good for CLI demo)

```bash
# Warm the cache so npx doesn't download during demo:
npx -y terraform-mcp-server --help
```

MCP config for this option (`.claude/settings.json`):

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

### Option B: Docker (more reliable, good for VSCode demo)

```bash
# Pull the image ahead of time:
docker pull hashicorp/terraform-mcp-server:latest
```

MCP config for this option (`.claude/settings.json`):

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "hashicorp/terraform-mcp-server:latest"
      ],
      "env": {}
    }
  }
}
```

If you need to pass environment variables (e.g., for HCP Terraform):

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "TFE_TOKEN",
        "-e", "TFE_ADDRESS",
        "hashicorp/terraform-mcp-server:latest"
      ],
      "env": {
        "TFE_TOKEN": "your-token-here",
        "TFE_ADDRESS": "https://app.terraform.io"
      }
    }
  }
}
```

### VSCode-specific MCP setup

If using the Claude Code VSCode extension, the MCP config goes in either:

1. **Project-level** (recommended for demo): `<project-dir>/.claude/settings.json`
2. **User-level**: `~/.claude/settings.json`

VSCode extension reads the same config format. No extra steps.

---

## 4. Create Demo Directories

```bash
# Naive dir — clean, no config
mkdir -p ~/demo-terraform-naive/

# Full dir — with MCP config
mkdir -p ~/demo-terraform-full/.claude/

# Write the MCP config (pick npx or docker from above)
cat > ~/demo-terraform-full/.claude/settings.json << 'EOF'
{
  "mcpServers": {
    "terraform": {
      "command": "npx",
      "args": ["-y", "terraform-mcp-server"],
      "env": {}
    }
  }
}
EOF
```

---

## 5. Pre-Clone Anton's Skill (backup)

You install this live in Act 2, but pre-clone so you have a fallback if GitHub is slow:

```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/terraform-skill-backup
```

During the demo (Act 2):
```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
```

If clone is slow live:
```bash
cp -r ~/terraform-skill-backup ~/.claude/skills/terraform
```

---

## 6. Skills Installation Strategy

Skills are installed LIVE to show incremental improvement:

| Act   | Skills state                    | How                                     |
|-------|---------------------------------|-----------------------------------------|
| Act 1 | NO skills, NO MCP              | `~/demo-terraform-naive/`, no config    |
| Act 2 | Install Anton's + HashiCorp    | `git clone` + `/plugin marketplace add` |
| Act 3 | Both skills + MCP active       | Same dir, everything loaded             |
| Act 4 | Same — now add tests           | `terraform test` on generated code      |

**Before Act 1, make sure no skills exist:**

```bash
rm -rf ~/.claude/skills 2>/dev/null
```

---

## 7. Dry Run Each Act

### Test Act 1 (naive):
```bash
cd ~/demo-terraform-naive/
claude   # or open in VSCode
# Paste the naive prompt from prompts.md
# Verify: output is basic single-file, insecure
```

### Test Act 2 (install skills):
```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
cd ~/demo-terraform-full/
claude   # or open in VSCode
# Verify: MCP tools show up
# Install HashiCorp skills: /plugin marketplace add hashicorp/agent-skills
# Verify: skills list shows up
```

### Test Act 3 (production prompt):
```bash
# Paste the production EC2 prompt from prompts.md
# Verify: output is multi-file, encrypted, tagged, HTTPS-only
```

### Test Act 4 (terraform test):
```bash
# Paste the "write tests" prompt from prompts.md
terraform init
terraform test -filter=tests/ec2.tftest.hcl
# Verify: tests run (pass or fail is fine — both are demo-able)
```

**After dry run, reset for demo:**
```bash
rm -rf ~/.claude/skills
rm -rf ~/demo-terraform-naive/*.tf
rm -rf ~/demo-terraform-full/*.tf ~/demo-terraform-full/tests/
```

---

## 8. VSCode Layout for Demo (if using extension)

```
┌─────────────────────────────┬────────────────────────┐
│                             │                        │
│    Editor pane              │    Claude Code panel    │
│    (shows generated .tf)    │    (chat + prompts)     │
│                             │                        │
│                             │                        │
└─────────────────────────────┴────────────────────────┘
```

- Open VSCode with the demo directory: `code ~/demo-terraform-full/`
- Claude panel on the right
- Editor on the left — files appear as Claude creates them
- Terminal at the bottom for `terraform init` / `terraform test`
- Font size: Cmd+= several times (or set `"editor.fontSize": 18` in settings)

---

## 9. Fallback Plans

**If MCP server doesn't connect:**
- Try the other method (npx ↔ Docker)
- If both fail: explain MCP verbally, focus on skills + terraform test
- The test-driven loop works without MCP

**If skills install fails live:**
- `cp -r ~/terraform-skill-backup ~/.claude/skills/terraform` (pre-cloned)
- For HashiCorp: `npx skills add hashicorp/agent-skills`
- Worst case: skip to Act 3/4, explain skills conceptually

**If terraform test fails on weird attribute paths:**
- That's actually good for the demo — show the fix loop
- If it keeps failing: `terraform validate` as simpler alternative

**If Docker isn't available:**
- Use npx method instead — same MCP server, different runner

---

## 10. Time Checkpoints

| Time  | Act     | What's happening                                       |
|-------|---------|-------------------------------------------------------|
| 0:00  | Opening | Problem statement — on camera, no terminal             |
| 2:00  | Act 1   | Naive prompt, show insecure output                     |
| 8:00  | Act 2   | Install MCP + skills, verify they loaded               |
| 18:00 | Act 3   | Production EC2 prompt, compare with naive               |
| 28:00 | Act 4   | Write tests, run them, fix failures, rerun              |
| 40:00 | Close   | Three-point recap, links                               |

---

## 11. Quick Recovery

```bash
# Claude Code hangs:
# Ctrl+C, restart: claude (or reopen VSCode panel)

# terraform test errors on init:
rm -rf .terraform .terraform.lock.hcl && terraform init

# npx MCP server errors:
npm cache clean --force && npx -y terraform-mcp-server --help

# Docker MCP server errors:
docker pull hashicorp/terraform-mcp-server:latest

# Skills not loading:
ls -la ~/.claude/skills/

# Nuclear reset:
rm -rf ~/.claude/skills
rm -rf ~/demo-terraform-naive/* ~/demo-terraform-full/*.tf
```
