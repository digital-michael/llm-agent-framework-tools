---
name: retrofit-project
description: Bring an existing project into compliance with the LLM Agent Collaboration Framework — creates .llm-framework.yml, docs/governance/ scaffolding, and populates repo context in the domain profile.
applyTo: "**"
---

# Skill: retrofit-project

Integrate an existing project with the LLM Agent Collaboration Framework. Unlike `scaffold-project` (which only writes `.llm-framework.yml`), this skill performs a full structured onboarding for projects that already have documentation, lessons, and conventions.

## When invoked

Use this skill when the user asks to:
- Bring an existing project into the framework
- Set up framework governance on a project that wasn't started with the framework
- Integrate a repo with their domain profile and infrastructure

## What to do

### Phase 1 — Audit (do not write anything yet)

1. Ask for (or confirm from context):
   - Project root path
   - Infrastructure path
   - Domain profile path (required — block if absent; instruct user to run `init-profile` first)
   - Repo name (used as the subdirectory name in the domain profile)

2. Read the project:
   - Project README
   - Any existing lessons, guidelines, or agent-working notes
   - Existing `docs/` structure or equivalent

3. Produce a **gap summary** — what exists, what is missing, what will be created. Present this to the user before proceeding.

### Phase 2 — Scaffold (after user confirms)

4. Write `.llm-framework.yml` at the project root. Do not overwrite if it exists without confirmation. (Follows `scaffold-project` contract.)

5. Create `docs/governance/` in the project repo with these files — do not overwrite existing files without confirmation:

   | File | Source |
   |---|---|
   | `docs/governance/README.md` | Generate: session-start load order + index of what to read |
   | `docs/governance/lessons-learned.md` | Generate: framework-format summary + pointers to existing lessons files |
   | `docs/governance/agent-assignment.md` | Copy from: `<infrastructure>/templates/agent-assignment.md` |
   | `docs/governance/session-context.md` | Copy from: `<infrastructure>/templates/session-context.md` |

   > Do NOT put agent behavior rules or doc-placement rules in `docs/governance/`. Those belong in the domain profile.

6. Write `<domain-profile>/<repo-name>/README.md` from the template at `<infrastructure>/templates/team/repo-name/README.md`. Pre-populate:
   - Project identity section from what was read in Phase 1
   - Session start load order with actual paths
   - Doc-placement rules (if the project has a strict structure)
   - Git workflow constraints

### Phase 3 — Retrospective

7. Log in `docs/governance/lessons-learned.md` under a retrofit session heading:
   - What was created
   - Any corrections still needed (as a numbered table)
   - Patterns that may be candidates for promotion to the domain overlay

8. Report: all created files, any skipped files (already existed), corrections needed, next steps.

## Constraints

- Block at Phase 1 if the domain profile path does not exist
- Never write agent behavior rules into `docs/governance/`
- Never overwrite existing files without explicit user confirmation
- Do not delete or move existing lessons files — only index them

## Contract reference

`llm-agent-framework/docs/tooling.md#retrofit-project`
