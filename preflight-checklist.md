# Pre-Flight Checklist — Demo Machine Setup

Run through this the night before or morning of. Takes ~15 min.

---

## 1. Software Versions

```bash
terraform version        # Need >= 1.6 (ideally 1.9+) for terraform test
node --version           # Need v18+ or v20+ for npx
git --version            # Need for cloning Anton's skill
claude --version         # Claude Code CLI
aws --version            # Optional — entire demo works without AWS creds
```

## 2. Warm the npx Cache

```bash
# So npx doesn't download anything during the live demo
npx -y terraform-mcp-server --help
npx skills add hashicorp/agent-skills   # or plan to install live in Step 2
```

## 3. Pre-Clone Anton's Skill (optional)

You install this live in Step 1, but pre-clone to a backup location so you
have a fallback if GitHub is slow during the demo:

```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/terraform-skill-backup
```

During demo Step 1, clone it for real:
```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
```

If clone is slow during demo, just copy the backup:
```bash
cp -r ~/terraform-skill-backup ~/.claude/skills/terraform
```

## 4. Create Two Demo Directories

### Directory 1: Naive (Step 0) — NO skills, NO MCP

```bash
mkdir -p ~/demo-terraform-naive/
cd ~/demo-terraform-naive/

# Verify: NO .claude/settings.json here
# Verify: NO skills in ~/.claude/skills/ yet (install live in Step 1)
```

### Directory 2: Full stack (Step 3) — has MCP config

```bash
mkdir -p ~/demo-terraform-full/.claude/
mkdir -p ~/demo-terraform-full/tests/mocks/

# Create MCP config
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

## 5. Skills Installation Strategy

The demo installs skills LIVE to show the incremental improvement:

| Step | Skills state | How |
|------|-------------|-----|
| Step 0 | NO skills anywhere | `~/.claude/skills/` should not exist |
| Step 1 | Install Anton's skill live | `git clone ... ~/.claude/skills/terraform` |
| Step 2 | Add HashiCorp skills live | `/plugin marketplace add hashicorp/agent-skills` |
| Step 3 | Both skills + MCP active | Switch to `~/demo-terraform-full/` |

**IMPORTANT:** Before Step 0, make sure `~/.claude/skills/` does not exist:
```bash
# Night before: if skills are already installed, move them
mv ~/.claude/skills ~/.claude/skills.bak 2>/dev/null

# After demo: restore
mv ~/.claude/skills.bak ~/.claude/skills 2>/dev/null
```

## 6. Dry Run: Test Each Step

### Test Step 0 (naive):
```bash
cd ~/demo-terraform-naive/
claude
> Create a reusable Terraform module for an S3 bucket with versioning.
# Verify: no skills kick in, output is basic
# Exit
```

### Test Step 1 (Anton's skill):
```bash
git clone https://github.com/antonbabenko/terraform-skill.git ~/.claude/skills/terraform
claude
> Create a reusable Terraform module for an S3 bucket with testing.
# Verify: output is modular, has .tftest.hcl, has CI workflow
# Exit
```

### Test Step 2 (HashiCorp skills):
```bash
# Inside Claude Code:
> /plugin marketplace add hashicorp/agent-skills
> Review this module for HashiCorp-style conventions.
# Verify: style refinements appear
# Exit
```

### Test Step 3 (MCP + tests):
```bash
cd ~/demo-terraform-full/
claude
> What terraform MCP tools do you have access to?
# Verify: lists registry lookup tools
# Exit
```

After dry run, reset for demo:
```bash
rm -rf ~/.claude/skills  # Will reinstall live during demo
```

## 7. Terminal Setup

```bash
# Increase font size: Cmd+= (Mac) or Ctrl+= (Linux)
# Dark theme
# Clear scrollback: Cmd+K or `clear`
```

## 8. Browser Tabs (reference only, not showing)

- https://github.com/antonbabenko/terraform-skill
- https://github.com/hashicorp/agent-skills
- https://github.com/hashicorp/terraform-mcp-server
- https://developer.hashicorp.com/terraform/language/tests

## 9. Fallback Plans

**If Anton's skill clone fails during Step 1:**
```bash
cp -r ~/terraform-skill-backup ~/.claude/skills/terraform
```

**If HashiCorp skills install fails during Step 2:**
- Try npx: `npx skills add hashicorp/agent-skills`
- Or skip Step 2 and explain the concept verbally with the table from the script
- Steps 1, 3, and 4 still work independently

**If MCP server doesn't connect in Step 3:**
- Demo still works: explain MCP verbally, focus on terraform test
- The test-driven loop (generate → test → fix → verify) is the strongest demo moment
  and works without MCP

**If terraform test fails on module attribute paths:**
- Module versions may have changed argument names
- Fallback: `terraform validate` (less dramatic but still shows the loop)
- Or use pre-baked test files from `demo-project/tests/`

**If no AWS credentials:**
- Fine. Entire demo runs with `mock_provider`. Zero AWS calls needed.

## 10. Time Checkpoints

| Time  | Step    | What's happening |
|-------|---------|-----------------|
| 0:00  | Opening | Problem statement — one central question |
| 2:00  | Step 0  | Naive prompt — establish the pain |
| 7:00  | Step 1  | Install Anton's skill, regenerate — best practices appear |
| 19:00 | Step 2  | Install HashiCorp skills, refine — product conventions appear |
| 31:00 | Step 3  | MCP server + terraform test — live data + contract |
| 43:00 | Close   | Four-layer stack recap + takeaways |

## 11. Quick Recovery Commands

```bash
# Claude Code hangs:
# Ctrl+C, then restart: claude

# terraform test errors on init:
rm -rf .terraform .terraform.lock.hcl && terraform init

# npx MCP server errors:
npm cache clean --force && npx -y terraform-mcp-server --help

# Skills not loading:
ls -la ~/.claude/skills/
# Check that skill folders contain instruction files, not just a README

# Reset everything to pre-demo state:
rm -rf ~/.claude/skills
rm -rf ~/demo-terraform-naive/*
rm -rf ~/demo-terraform-full/*.tf ~/demo-terraform-full/modules/ ~/demo-terraform-full/tests/
```
