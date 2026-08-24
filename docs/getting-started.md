# Getting Started — Tools and Skills

> How to install and use the LLM Agent Framework tools on your platform.

---

## Prerequisites

- `llm-agent-framework` cloned to a known local path (e.g., `~/Projects/infrastructure`)
- At least one project with `.llm-framework.yml` configured

---

## Choose Your Platform

### VS Code Copilot Skills

For VS Code with GitHub Copilot:

1. Copy the `skills/` directory contents to your VS Code user prompts folder, or reference them from a workspace `.github/` directory
2. Skills will appear in the Copilot agent mode skill list

See [../skills/README.md](../skills/README.md) for detailed setup.

### Shell Scripts (Platform-Agnostic Fallback)

For any environment without MCP or VS Code:

1. Ensure Bash 4.4+ is available
2. Make scripts executable: `chmod +x scripts/*.sh`
3. Run directly: `./scripts/init-profile.sh --type personal --target ~/Projects/personal/jane`

See [../scripts/README.md](../scripts/README.md) for usage.

---

## Tool Quick Reference

| Tool | What It Does | When to Use |
|---|---|---|
| `init-profile` | Scaffold personal or team profile repo from templates | First-time setup |
| `upgrade-template` | Apply infrastructure template updates to your profile | After infrastructure updates |
| `scaffold-project` | Write `.llm-framework.yml` for a project | Starting a new project |

---

## Version Alignment

This tooling repo tracks `llm-agent-framework` by template version. Check `scripts/init-profile.sh` for the `FRAMEWORK_VERSION` it was built against. If your infrastructure repo is on a newer version, update the tooling repo.

---

## MCP (Model Context Protocol)

Not currently implemented in this repo. MCP remains a valid platform per the contract (`llm-agent-framework/docs/tooling.md`) — an `mcp/` stub existed here but was removed 2026-08-12 (never past its initial commit, no working implementation). The Shell Scripts fallback above already covers any MCP-capable client that can also shell out (e.g. Claude Code). Build a real implementation if a client that needs MCP tool calling *without* shell access emerges — don't resurrect the stub.
