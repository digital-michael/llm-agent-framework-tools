# MCP Tools

Each subdirectory contains one tool implementation. Each tool consists of:
- `schema.json` — JSON Schema for the tool's inputs and outputs (MCP tool definition)
- `implementation notes` — how the tool operates (see the contract in `llm-agent-framework/docs/tooling.md`)

Implementation files (`index.js`, `index.py`, etc.) are added when the tool is built out.
