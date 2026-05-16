# Glossary of Terms — LLM Agent Framework Tools

> Key terms used in this tooling repository. For framework-level concepts, see the main glossary at `../llm-agent-framework/glossary-of-terms.md`.

---

## Tool Terms

### Context Hydration (`context-hydration`)
An agent-side operation (not user-invoked) that reads `.llm-framework.yml` at session start, resolves the layer stack (infrastructure → team → personal), and makes the resulting governance layer available to the agent. The contract is defined in `../llm-agent-framework/docs/tooling.md`.

### Contract
The specification of what a tool must do — its name, purpose, inputs, and outputs — independent of any platform implementation. Contracts live in `llm-agent-framework/docs/tooling.md`. This tooling repo provides implementations of those contracts.

### init-profile
A tool that scaffolds a new personal or team profile repo from infrastructure templates. Copies the appropriate `templates/<type>/` directory to a target path as plain files (no git relationship to infrastructure). Contract in `../llm-agent-framework/docs/tooling.md#init-profile`.

### scaffold-project
A tool that writes `.llm-framework.yml` to a project root, connecting it to the framework layer stack. Validates that declared paths exist before writing. Contract in `../llm-agent-framework/docs/tooling.md#scaffold-project`.

### upgrade-template
A tool that detects when an infrastructure template version is newer than a profile's filled-out copy, and applies structural updates without overwriting user-supplied content. Contract in `../llm-agent-framework/docs/tooling.md#upgrade-template`.

---

## Platform Terms

### MCP (Model Context Protocol)
An open protocol for connecting LLM clients to external tools and data sources. Tools implemented in `mcp/tools/` follow the MCP tool schema format. See `mcp/README.md` for setup.

### SKILL.md
The file format used by VS Code Copilot for agent skills. Each skill defines when it is invoked and what the agent should do. Skills in `skills/` implement the same contracts as the MCP tools. See `skills/README.md` for setup.

### Template Version
A version stamp (`template-version: 1.0.0`) in the YAML front matter of each governance and template file. Used by `upgrade-template` to detect drift between infrastructure and filled-out profile copies.

---

## Framework Terms (summary)

For full definitions, see `../llm-agent-framework/glossary-of-terms.md`.

| Term | Brief Definition |
|---|---|
| `.llm-framework.yml` | Project-root config file declaring paths to each framework layer |
| Infrastructure | The `llm-agent-framework/` repo — stable, tooling-agnostic defaults |
| Personal profile | Private per-person repo overriding personal governance preferences |
| Team profile | Shared team repo overriding team-level governance preferences |
| Operating mode | Standalone (infra only) / Team / Full (infra + team + personal) |
| Override system | `replacement` replaces the full file; `extend` replaces named items only |
