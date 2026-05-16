---
name: scaffold-project
description: Write .llm-framework.yml for a new or existing project repository, connecting it to the framework layer stack.
applyTo: "**"
---

# Skill: scaffold-project

Write `.llm-framework.yml` at the project root to connect a project to the LLM Agent Collaboration Framework.

## When invoked

Use this skill when the user asks to:
- Set up a project to use the framework
- Connect a project to their personal/team profile
- Create or update `.llm-framework.yml`

## What to do

1. Ask for (or confirm from context):
   - Project root path
   - Infrastructure path (required)
   - Team profile path (optional)
   - Personal profile path (optional)

2. Validate: confirm each declared path exists before writing.

3. Determine the operating mode:
   - Infrastructure only → `Standalone`
   - Infrastructure + team → `Team`
   - Infrastructure + team + personal → `Full`
   - Infrastructure + personal (no team) → `Full` (personal layer active)

4. Write `.llm-framework.yml` to the project root. Do not overwrite an existing one unless the user explicitly confirms.

5. Report: the config path, operating mode, and next steps (e.g., load context at next session start).

## Contract reference

`llm-agent-framework/docs/tooling.md#scaffold-project`
