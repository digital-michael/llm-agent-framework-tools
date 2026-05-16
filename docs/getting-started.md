# Getting Started — Tools and Skills

> How to install and use the LLM Agent Framework tools on your platform.

---

## Prerequisites

- `llm-agent-framework` cloned to a known local path (e.g., `~/Projects/infrastructure`)
- At least one project with `.llm-framework.yml` configured

---

## Choose Your Platform

### MCP (Model Context Protocol)

For LLM clients that support MCP tool calling (Claude Desktop, VS Code with MCP extension, etc.):

1. Configure your MCP client to load the server from `mcp/mcp.json`
2. Set the `INFRASTRUCTURE_PATH` environment variable to your infrastructure repo path
3. Tools will be available as callable tools in your LLM session

See [../mcp/README.md](../mcp/README.md) for detailed setup.

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

This tooling repo tracks `llm-agent-framework` by template version. Check `mcp/mcp.json` or `scripts/init-profile.sh` for the `FRAMEWORK_VERSION` they were built against. If your infrastructure repo is on a newer version, update the tooling repo.
