---
name: init-profile
description: Scaffold a new personal or team profile repo from llm-agent-framework infrastructure templates.
applyTo: "**"
---

# Skill: init-profile

Scaffold a new personal or team profile repo from the `llm-agent-framework` infrastructure templates.

## When invoked

Use this skill when the user asks to:
- Set up their personal framework profile
- Create a team profile repo for their organization
- Initialize a new profile from the framework templates

## What to do

1. Ask for (or confirm from context):
   - Profile type: `personal` or `team`
   - Target path for the new repo
   - Path to the infrastructure repo (`llm-agent-framework`)

2. Copy the contents of `<infrastructure_path>/templates/<profile_type>/` to the target path as plain files. Do not establish any git relationship between the target and infrastructure.

3. If the user wants git init (default yes), run `git init` at the target path.

4. Offer to write `.llm-framework.yml` to a named project if the user provides a project path.

5. Confirm the created files and provide next steps (fill in the template files, then run `scaffold-project` to connect a project).

## Contract reference

`llm-agent-framework/docs/tooling.md#init-profile`
