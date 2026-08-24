# LLM Agent Framework — Tools and Skills

> **Companion repo to:** `llm-agent-framework`
> **Purpose:** Platform-specific implementations of the tools and skills defined in the framework.

---

## What This Is

This repository provides implementations of the tool and skill contracts defined in:
[`llm-agent-framework/docs/tooling.md`](../llm-agent-framework/docs/tooling.md)

The infrastructure repo (`llm-agent-framework`) defines **what** each tool must do. This repo provides **how** for specific platforms.

---

## Platform Implementations

| Directory | Platform | Format |
|---|---|---|
| `skills/` | VS Code Copilot | `SKILL.md` skill files |
| `scripts/` | Platform-agnostic | Bash scripts (fallback for any environment) |

MCP (Model Context Protocol) remains a valid platform per the contract (`llm-agent-framework/docs/tooling.md`), but this repo doesn't currently implement it — the `mcp/` stub here was removed 2026-08-12 (never past `Initial commit`, no working implementation, superseded by the scripts/skills implementations above). Build one if a real MCP-only consumer emerges; don't resurrect the stub.

You only need the implementation(s) for your platform. Teams may provide their own implementations as long as they satisfy the contracts.

---

## Tools Provided

| Tool | Purpose |
|---|---|
| `init-profile` | Scaffold a personal or team profile repo from infrastructure templates |
| `upgrade-template` | Detect and apply infrastructure template updates to filled-out profile files |
| `scaffold-project` | Write `.llm-framework.yml` for a new or existing project repo |
| `retrofit-project` | Full onboarding for an existing project — governance scaffolding, domain repo context, lessons migration |

See [`llm-agent-framework/docs/tooling.md`](../llm-agent-framework/docs/tooling.md) for full contract definitions.

---

## Directory Structure

```
llm-agent-framework-tools/
├── README.md                      # This file
├── docs/
│   └── getting-started.md         # How to install and use
├── skills/
│   ├── README.md                  # VS Code Copilot skill setup
│   ├── init-profile/              # Skill: init-profile
│   ├── upgrade-template/          # Skill: upgrade-template
│   └── scaffold-project/          # Skill: scaffold-project
└── scripts/
    ├── README.md                  # Script usage
    ├── init-profile.sh
    ├── upgrade-template.sh
    └── scaffold-project.sh
```

---

## Relationship to Infrastructure

```
llm-agent-framework/          ← infrastructure: stable, tooling-agnostic
  docs/tooling.md             ← contract definitions (source of truth)

llm-agent-framework-tools/   ← this repo: platform-specific implementations
  skills/                     ← VS Code Copilot implementation
  scripts/                    ← shell script fallback
```

**Direction of dependency:** tooling depends on infrastructure. Infrastructure has no dependency on tooling.

---

## Getting Started

See [docs/getting-started.md](docs/getting-started.md) for installation and setup instructions per platform.
