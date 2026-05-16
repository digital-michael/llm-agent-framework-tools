# Scripts — Platform-Agnostic Shell Fallbacks

> Bash scripts implementing the LLM Agent Framework tools. These work on any system with Bash 4.4+.
> Use these when MCP and VS Code Copilot skills are not available.

---

## Requirements

- Bash 4.4+
- Standard POSIX utilities (`cp`, `mkdir`, `git`, etc.)

## Setup

```bash
chmod +x scripts/*.sh
```

## Usage

### init-profile

```bash
./init-profile.sh --type personal --target ~/Projects/personal/jane --infra ~/Projects/infrastructure
./init-profile.sh --type team     --target ~/Projects/team/acme    --infra ~/Projects/infrastructure
```

### upgrade-template

```bash
./upgrade-template.sh --profile ~/Projects/personal/jane/context-protocol.md \
                      --template ~/Projects/infrastructure/templates/personal/context-protocol.md
```

### scaffold-project

```bash
./scaffold-project.sh --project ~/Projects/my-app \
                      --infra   ~/Projects/infrastructure \
                      --team    ~/Projects/team/acme \
                      --personal ~/Projects/personal/jane
```

## Script Contracts

All scripts implement the same contracts as the MCP tools and skills. See `llm-agent-framework/docs/tooling.md` for the full contract definitions.
