# VS Code Copilot Skills

> Platform-specific: these skills use VS Code Copilot's SKILL.md format and are only applicable in VS Code with GitHub Copilot.

---

## Setup

1. Copy the skill directories you want to your VS Code user prompts folder (e.g., `~/.config/Code/User/prompts/`)
2. Or reference them in your workspace `.github/prompts/` directory
3. The skills will appear in Copilot's agent mode skill list

## Available Skills

| Skill | File | Purpose |
|---|---|---|
| init-profile | `init-profile/SKILL.md` | Scaffold a personal or team profile repo |
| upgrade-template | `upgrade-template/SKILL.md` | Apply template updates to a profile file |
| scaffold-project | `scaffold-project/SKILL.md` | Write `.llm-framework.yml` for a project |

## Skill Contracts

All skills implement the same contracts as the MCP tools. See `llm-agent-framework/docs/tooling.md` for the full contract definitions.
