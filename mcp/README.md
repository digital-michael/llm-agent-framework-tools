# MCP — Setup and Configuration

> MCP (Model Context Protocol) implementation of the LLM Agent Framework tools.
> Compatible with: Claude Desktop, VS Code MCP extension, and any MCP-compliant client.

---

## Setup

1. Point your MCP client at this directory's `mcp.json`
2. Set required environment variables (see below)
3. Restart your MCP client to load the tools

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `INFRASTRUCTURE_PATH` | Yes | Absolute path to your `llm-agent-framework` repo |
| `DEFAULT_PROJECTS_PATH` | No | Default parent path for new profile repos (default: `~/Projects`) |

### Example MCP client config (Claude Desktop `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "llm-agent-framework": {
      "command": "node",
      "args": ["<path-to-this-repo>/mcp/server.js"],
      "env": {
        "INFRASTRUCTURE_PATH": "/home/user/Projects/infrastructure"
      }
    }
  }
}
```

---

## Available Tools

| Tool | MCP Name | Description |
|---|---|---|
| init-profile | `init_profile` | Scaffold a personal or team profile repo |
| upgrade-template | `upgrade_template` | Apply template updates to a filled-out profile file |
| scaffold-project | `scaffold_project` | Write `.llm-framework.yml` for a project |

---

## Tool Contracts

All tools implement the contracts defined in:
`llm-agent-framework/docs/tooling.md`
