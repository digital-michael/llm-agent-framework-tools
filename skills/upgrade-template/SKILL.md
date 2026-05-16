---
name: upgrade-template
description: Detect and apply infrastructure template updates to a filled-out personal or team profile file.
applyTo: "**"
---

# Skill: upgrade-template

Check whether a filled-out profile file is behind the current infrastructure template version, and apply updates.

## When invoked

Use this skill when the user asks to:
- Upgrade their profile to the latest framework version
- Check for template drift in a profile file
- Apply infrastructure updates to a specific file

## What to do

1. Ask for (or confirm from context):
   - Path to the filled-out profile file
   - Path to the infrastructure template it is based on (inferred from file name/type if possible)

2. Read the `template-version` field from both files.

3. If versions match: report no action needed.

4. If infrastructure version is newer:
   - Diff the structural elements (sections, headings, prompt fields) — not user-supplied content
   - Present the structural changes to the user
   - Apply only confirmed changes
   - Never overwrite user-supplied content without explicit confirmation

5. Update the `template-version` stamp in the profile file to match infrastructure.

6. Report: what changed, what was skipped, and the new version.

## Contract reference

`llm-agent-framework/docs/tooling.md#upgrade-template`
