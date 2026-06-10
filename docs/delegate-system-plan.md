# LLM Delegate System — Implementation Plan

> Local-first AI delegation: Claude plans, local LLMs execute, Flowise orchestrates, MCP exposes.

---

## Table of Contents

1. [Vision and Goals](#1-vision-and-goals)
2. [Architecture Overview](#2-architecture-overview)
   - [Component Map](#21-component-map)
   - [Request Flow](#22-request-flow)
   - [Container Stack](#23-container-stack)
3. [Command Surface (MCP Tools)](#3-command-surface-mcp-tools)
4. [Data Model](#4-data-model)
   - [PostgreSQL Schema](#41-postgresql-schema)
   - [Routing Rules](#42-routing-rules)
5. [Flowise Flows](#5-flowise-flows)
   - [delegate flow](#51-delegate-flow)
   - [plan flow](#52-plan-flow)
   - [status flow](#53-status-flow)
   - [start flow](#54-start-flow)
   - [stop flow](#55-stop-flow)
   - [pause flow](#56-pause-flow)
   - [models flow](#57-models-flow)
6. [Thin MCP Adapter](#6-thin-mcp-adapter)
7. [LiteLLM Configuration](#7-litellm-configuration)
8. [Phase Plan](#8-phase-plan)
   - [Phase 1 — Container Stack](#phase-1--container-stack)
   - [Phase 2 — Data Layer](#phase-2--data-layer)
   - [Phase 3 — Flowise Flows](#phase-3--flowise-flows)
   - [Phase 4 — Thin MCP Adapter](#phase-4--thin-mcp-adapter)
   - [Phase 5 — Smart Routing](#phase-5--smart-routing)
   - [Phase 6 — Control Flows and Concurrency](#phase-6--control-flows-and-concurrency)
9. [Effort Estimate](#9-effort-estimate)
10. [Open Decisions](#10-open-decisions)

---

## 1. Vision and Goals

Use a frontier LLM (Claude) for planning, judgment, and orchestration. Delegate self-contained
implementation tasks to local LLMs managed through a containerized stack. All commands are
exposed as MCP tools in VS Code — no custom VS Code extensions, no thick MCP client.

**Core goals:**

- MCP adapter is thin — it defines tool schemas and proxies to Flowise. No business logic.
- All orchestration, agentic loops, HITL, and state management live inside Flowise.
- All infrastructure components (Flowise, LiteLLM, Ollama, PostgreSQL) run in Podman containers.
- Models are stored on the host filesystem, never in volumes or images.
- The system supports concurrent delegates with independent execution and per-delegate HITL.
- Smart routing selects the best available local model per task type using user preferences.

---

## 2. Architecture Overview

### 2.1 Component Map

```
VS Code
  └── GitHub Copilot / Claude (planning + orchestration)
  └── MCP client (.vscode/mcp.json)
          │ stdio or localhost HTTP
          ▼
  Thin MCP Adapter  (local Python process, NOT in container)
          │ POST /api/v1/prediction/{flowId}
          ▼
  ┌─────────────────────────── Podman Pod ────────────────────────────┐
  │                                                                    │
  │  Flowise (AgentFlow V2)          PostgreSQL                        │
  │    delegate flow          ◄──►     delegates table                 │
  │    plan flow                       plans table                     │
  │    status flow                     user_preferences table          │
  │    start/stop/pause flows          (+ Flowise native tables)       │
  │    models flow                                                     │
  │         │                                                          │
  │         ▼                                                          │
  │  LiteLLM Proxy  (:4000)                                            │
  │         │ model alias routing                                      │
  │         ▼                                                          │
  │  Ollama  (:11434)                                                  │
  │                                                                    │
  └────────────────────────────────────────────────────────────────────┘
          │ bind mounts
          ▼
  Host filesystem
    ~/.ollama/models   (model weights — never in volumes)
    ~/Projects         (workspace files — read/write by delegates)
```

### 2.2 Request Flow

**Delegate execution (happy path):**

```
1. User: /delegate "plan.md" phase:2 step:1
2. MCP Adapter: POST /api/v1/prediction/{delegateFlowId}
                body: { plan_ref, phase, step, session_id }
3. Adapter: returns immediately with { delegate_id, status: "started" }
4. Flowise delegate flow:
   a. TQ Routing Node → selects model alias from user_preferences
   b. Agent Node reads project files, calls LiteLLM
   c. LiteLLM routes to Ollama → local LLM processes
   d. Agent writes files, continues loop
   e. If ambiguity → Human Input Node pauses, checkpoints
   f. User answers in Flowise UI (or VS Code via /status)
   g. Flow resumes, continues to completion
   h. Writes final status to delegates table
5. User: /status → sees all delegates and their current state
```

### 2.3 Container Stack

```
┌─────────────────────────────────────────────────┐
│  Podman Pod: llm-delegate                        │
│                                                  │
│  flowise    :3000   (web UI + prediction API)    │
│  litellm    :4000   (model router)               │
│  ollama     :11434  (local model serving)        │
│  postgres   :5432   (state + Flowise data)       │
│                                                  │
│  Bind mounts:                                    │
│    ~/.ollama → /root/.ollama  (Ollama models)    │
│    ~/Projects → /projects     (workspace files)  │
└─────────────────────────────────────────────────┘
```

Podman rootless with `--userns=keep-id` or explicit UID mapping handles bind mount
permissions for the macOS host user.

---

## 3. Command Surface (MCP Tools)

All tools are defined in the thin MCP adapter. Each tool calls one Flowise flow via HTTP.

| MCP Tool | Description | Flowise Flow | Returns |
|---|---|---|---|
| `delegate` | Submit a plan phase/step for local LLM execution | delegate flow | `{ delegate_id, status }` |
| `plan` | Pre-flight check before delegation; no auto-start | plan flow | `{ plan_id, questions[], ready }` |
| `status` | Overview of all active delegates and plans | status flow | `{ delegates[], plans[], models[] }` |
| `start` | Start a queued plan or resume a paused delegate | start flow | `{ id, status }` |
| `stop` | Stop one or all running delegates | stop flow | `{ id, status, warning }` |
| `pause` | Pause one or all running delegates | pause flow | `{ id, status }` |
| `models` | List, add, delete, upgrade, retire, prefer models | models flow | varies |

### Tool Schemas (abbreviated)

```python
# delegate
{
  "plan_ref":  str,   # file path OR plan_id — see Open Decision #2
  "phase":     int,
  "step":      int,
  "context":   str,   # optional override or additional instructions
  "scope":     str,   # optional: project subdirectory path restriction
}

# models
{
  "action":    Literal["list", "add", "delete", "upgrade", "retire", "prefer"],
  "name":      str,   # model name (required for all except list)
}

# stop / pause
{
  "id":        str,   # delegate_id or "all"
}
```

---

## 4. Data Model

### 4.1 PostgreSQL Schema

```sql
-- Delegate execution records
CREATE TABLE delegates (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    flowise_session TEXT NOT NULL,           -- Flowise execution session ID
    plan_ref        TEXT,                    -- file path or plan_id
    phase           INT,
    step            INT,
    status          TEXT NOT NULL DEFAULT 'queued',  -- queued|running|paused|awaiting_input|done|stopped|failed
    model_alias     TEXT,                    -- which LiteLLM alias was used
    project_scope   TEXT,                    -- restricted subdirectory (nullable = unrestricted)
    started_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    error           TEXT,
    file_ops_log    JSONB DEFAULT '[]'::jsonb  -- [{op, path, timestamp}]
);

-- Plan records
CREATE TABLE plans (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    flowise_session TEXT,
    source_ref      TEXT,                    -- original input (file path or inline)
    content         TEXT,                    -- structured plan content
    status          TEXT NOT NULL DEFAULT 'draft',  -- draft|ready|delegating|done
    questions       JSONB DEFAULT '[]'::jsonb,      -- unresolved questions from /plan
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- User and routing preferences
CREATE TABLE user_preferences (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_delegates_status    ON delegates (status);
CREATE INDEX idx_delegates_updated   ON delegates (updated_at DESC);
CREATE INDEX idx_plans_status        ON plans (status);
```

### 4.2 Routing Rules

Seeded into `user_preferences` at setup time. The delegate flow reads these to select a
LiteLLM model alias.

| Key | Default Value | Description |
|---|---|---|
| `routing.code_heavy` | `code-heavy` | Alias for complex refactor, architecture tasks |
| `routing.code_fast` | `code-fast` | Alias for tests, docs, small edits |
| `routing.planning` | `code-heavy` | Alias for `/plan` flow LLM calls |
| `routing.preferred_model` | `""` | Override: force all delegates to this alias |
| `host.memory_gb` | `16` | Used by future auto-routing logic |

---

## 5. Flowise Flows

All flows are AgentFlow V2. They are exported as JSON and version-controlled in this repo
under `flowise-flows/`. Imported via `POST /api/v1/agentflows` at setup time.

### 5.1 Delegate Flow

**Purpose:** Execute one plan phase/step autonomously using a local LLM.

```
Start Node
  → Custom Function Node: read routing prefs + select model alias
  → Condition Node: is scope set? → restrict file tool if yes
  → Agent Node (model = $flow.state.model_alias)
      Tools: read_file, write_file, list_directory, search_code
      Knowledge: project directory
      Loop: yes (loops back for multi-step execution)
  → Human Input Node (when ambiguity detected)
      Proceed → continue agent loop
      Reject  → stop and record reason
  → Custom Function Node: write final status to delegates table
  → Direct Reply Node: summary of changes made
```

**Flow State keys:** `model_alias`, `delegate_id`, `project_scope`, `iteration_count`

### 5.2 Plan Flow

**Purpose:** Analyze a plan phase/step, surface questions, but do not start execution.

```
Start Node
  → LLM Node (model = routing.planning alias)
      Prompt: analyze plan for ambiguities, missing context, risks
      Output: structured JSON { questions[], ready, notes }
  → Custom Function Node: write plan record to plans table
  → Condition Node: questions exist?
      Yes → Human Input Node: present questions to user
      No  → Direct Reply: "Plan is clear, ready to delegate"
  → Direct Reply Node: plan_id + question list
```

### 5.3 Status Flow

**Purpose:** Return current state of all delegates and plans.

```
Start Node
  → Custom Function Node:
      SELECT * FROM delegates ORDER BY updated_at DESC LIMIT 20
      SELECT * FROM plans WHERE status != 'done'
      Format as structured summary
  → Direct Reply Node: formatted status output
```

### 5.4 Start Flow

**Purpose:** Resume a paused delegate or start a queued plan.

```
Start Node (input: id)
  → Custom Function Node: look up id in delegates or plans table
  → Condition Node: type?
      Delegate → HTTP Node: POST /api/v1/chatmessage/resume/{session_id}
      Plan     → Trigger delegate flow with plan context
  → Custom Function Node: update status to 'running'
  → Direct Reply Node: confirmation
```

### 5.5 Stop Flow

**Purpose:** Terminate one or all running delegates.

```
Start Node (input: id or "all")
  → Custom Function Node: resolve session IDs from delegates table
  → Iteration Node (for each session):
      HTTP Node: DELETE /api/v1/execution/{session_id}
      Custom Function Node: update delegates.status = 'stopped'
  → Direct Reply Node: stopped IDs + warning about partial writes
```

### 5.6 Pause Flow

**Purpose:** Signal a delegate to pause at its next HITL checkpoint.

```
Start Node (input: id or "all")
  → Custom Function Node: set delegates.status = 'pause_requested'
      (flow checks this flag at each loop iteration)
  → Direct Reply Node: "Pause requested — will halt at next checkpoint"
```

**Note:** True mid-step pause is not possible in Flowise. The delegate flow checks
`$flow.state.pause_requested` at the top of each loop iteration. See [Open Decision #5](#open-decision-5--pause-semantics).

### 5.7 Models Flow

**Purpose:** Manage local model roster via Ollama and LiteLLM APIs.

```
Start Node (input: action, name)
  → Condition Agent Node: route by action
      list    → HTTP: GET ollama:11434/api/tags
                HTTP: GET litellm:4000/model/info
                → Direct Reply: combined model list
      add     → HTTP: POST ollama:11434/api/pull (body: { name })
                HTTP: POST litellm:4000/model/new
                → Direct Reply: pull status
      delete  → Human Input Node: "Confirm delete — cannot be undone"
                → HTTP: DELETE ollama:11434/api/delete
                → HTTP: DELETE litellm:4000/model/{name}
      upgrade → HTTP: POST ollama:11434/api/pull (re-pull latest tag)
      retire  → Human Input Node: confirm
                → Custom Function Node: mark alias inactive in user_preferences
      prefer  → Custom Function Node: update routing.preferred_model in user_preferences
```

---

## 6. Thin MCP Adapter

A single Python file (~150 lines). Runs as a local process. Registered in `.vscode/mcp.json`.

**Responsibilities:**
- Define MCP tool schemas for all 7 commands
- Proxy each tool call to the appropriate Flowise flow via `POST /api/v1/prediction/{flowId}`
- Use fire-and-forget for `delegate` and `start` (return delegate_id immediately)
- Use synchronous response for `status`, `models list`, `stop`, `pause`
- Read flow IDs and Flowise base URL from environment variables
- Read PostgreSQL connection for `status` (to bypass Flowise for fast reads)
- Never hardcode credentials

**Technology:** Python `mcp` SDK (official), `httpx` for async HTTP, `asyncpg` for direct PG reads.

**Configuration (`.vscode/mcp.json`):**

```json
{
  "servers": {
    "llm-delegate": {
      "type": "stdio",
      "command": "python",
      "args": ["${workspaceFolder}/../llm-agent-framework-tools/mcp/delegate-adapter.py"],
      "env": {
        "FLOWISE_BASE_URL": "http://localhost:3000",
        "FLOWISE_API_KEY": "${input:flowiseApiKey}",
        "POSTGRES_DSN": "${input:postgresDsn}",
        "FLOW_ID_DELEGATE": "${input:flowIdDelegate}",
        "FLOW_ID_PLAN":     "${input:flowIdPlan}",
        "FLOW_ID_STATUS":   "${input:flowIdStatus}",
        "FLOW_ID_START":    "${input:flowIdStart}",
        "FLOW_ID_STOP":     "${input:flowIdStop}",
        "FLOW_ID_PAUSE":    "${input:flowIdPause}",
        "FLOW_ID_MODELS":   "${input:flowIdModels}"
      }
    }
  }
}
```

Flow IDs are obtained after importing flows into Flowise (Phase 3) and stored in a local
`.env` file that populates the `input:` variables via VS Code's MCP input variable support.

---

## 7. LiteLLM Configuration

`litellm-config.yaml` — version-controlled, mounted read-only into the LiteLLM container.

```yaml
model_list:
  # Code-heavy: complex refactors, architecture, multi-file changes
  - model_name: code-heavy
    litellm_params:
      model: ollama/deepseek-coder-v2:16b
      api_base: http://ollama:11434

  # Code-fast: tests, docs, small edits, quick analysis
  - model_name: code-fast
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: http://ollama:11434

  # Fallback: catches unknown alias names
  - model_name: fallback
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: http://ollama:11434

general_settings:
  fallback_models: ["fallback"]
  num_retries: 2
  request_timeout: 600      # 10 min — code tasks run long

litellm_settings:
  drop_params: true
```

**Starting model roster (pull during Phase 1 setup):**

| Alias | Ollama Tag | RAM (~) | Use |
|---|---|---|---|
| `code-heavy` | `deepseek-coder-v2:16b` | ~10 GB | complex tasks |
| `code-fast` | `qwen2.5-coder:7b` | ~5 GB | fast tasks |

Adjust tags to fit available RAM. Add models later via `/models add`.

---

## 8. Phase Plan

### Phase 1 — Container Stack

**Goal:** All four services running and connected. Validate with direct API calls.

- [ ] `podman-compose.yml` with flowise, litellm, ollama, postgres services
- [ ] Bind mounts: `~/.ollama` → Ollama container, `~/Projects` → Flowise container
- [ ] `--userns=keep-id` UID mapping for rootless Podman bind mount permissions
- [ ] Environment variable and secrets strategy (`.env` file, gitignored)
- [ ] `litellm-config.yaml` with initial two aliases
- [ ] Pull starter models via `podman exec ollama ollama pull deepseek-coder-v2:16b`
- [ ] Smoke test: `curl http://localhost:4000/model/info` returns both aliases
- [ ] Smoke test: `curl http://localhost:3000/api/v1/ping` returns OK

**Estimated effort:** 1.0 – 1.5 h

---

### Phase 2 — Data Layer

**Goal:** PostgreSQL schema in place, seeded with routing defaults.

- [ ] Migration script: create `delegates`, `plans`, `user_preferences` tables
- [ ] Migration runner (simple shell script, idempotent)
- [ ] Seed script: insert default routing rules into `user_preferences`
- [ ] Validate Flowise connects to PG and its own native tables initialize
- [ ] Confirm `delegates.file_ops_log` JSONB column accepts sample data

**Estimated effort:** 0.5 – 0.75 h

---

### Phase 3 — Flowise Flows

**Goal:** All 7 flows built, imported, and individually smoke-tested via the Flowise UI.

- [ ] Export Flowise node type schema (one-time, via Flowise UI or API)
- [ ] Build and test `plan` flow (simplest — no loop, no file access)
- [ ] Build and test `status` flow (read-only PG query)
- [ ] Build and test `delegate` flow (full agent loop + HITL)
- [ ] Build and test `start` / `stop` / `pause` flows
- [ ] Build and test `models` flow (HTTP chains to Ollama + LiteLLM)
- [ ] Export all flows as JSON, commit to `flowise-flows/` directory
- [ ] Write import script: `POST /api/v1/agentflows` for each flow JSON
- [ ] Record all flow IDs for use in MCP adapter `.env`

**Estimated effort:** 3.0 – 4.5 h

> This is the largest phase. The delegate flow alone is 8+ nodes with ~15 connections.
> Build in Flowise visual builder; export JSON; do not hand-author graph JSON.

---

### Phase 4 — Thin MCP Adapter

**Goal:** All 7 MCP tools working end-to-end from VS Code chat.

- [ ] `delegate-adapter.py`: MCP tool definitions for all 7 commands
- [ ] Fire-and-forget pattern for `delegate` and `start`
- [ ] Synchronous response pattern for `status`, `stop`, `pause`, `models`
- [ ] Direct PostgreSQL read for `/status` (bypass Flowise for speed)
- [ ] `.vscode/mcp.json` with `input:` variable references for all credentials
- [ ] `.env.example` documenting all required variables
- [ ] Trust and start adapter in VS Code; confirm tools appear in chat
- [ ] End-to-end test: `/plan` → `/delegate` → `/status` from VS Code

**Estimated effort:** 0.75 – 1.0 h

---

### Phase 5 — Smart Routing

**Goal:** Model selection driven by task type and user preferences.

- [ ] `user_preferences` seeded with routing keys (Phase 2 prerequisite)
- [ ] Custom Function Node in delegate flow reads routing prefs from PG
- [ ] `routing.preferred_model` override logic (when set, bypasses task-type routing)
- [ ] `/models prefer <name>` updates `routing.preferred_model` in PG
- [ ] LiteLLM fallback behavior validated (unknown alias → fallback model)
- [ ] Test: update routing pref, run delegate, confirm different model used

**Estimated effort:** 0.75 – 1.0 h

---

### Phase 6 — Control Flows and Concurrency

**Goal:** `start`, `stop`, `pause` working reliably; 3+ concurrent delegates validated.

- [ ] `pause` semantics implemented via `$flow.state.pause_requested` flag check
- [ ] `stop` surfaces partial-write warning in Direct Reply output
- [ ] Concurrent delegate test: trigger 3 delegates simultaneously, observe Ollama queue behavior
- [ ] Document Ollama single-request-per-model behavior in `STATUS.md`
- [ ] HITL round-trip test: delegate pauses with question, user answers in Flowise UI, resumes
- [ ] Error branch validation: missing file, LLM call failure, tool error

**Estimated effort:** 1.0 – 1.5 h

---

## 9. Effort Estimate

| Phase | Work | Agent Hours |
|---|---|---|
| 1 — Container Stack | podman-compose, litellm config, bind mounts, smoke tests | 1.0 – 1.5 h |
| 2 — Data Layer | PG schema, migration runner, seed data | 0.5 – 0.75 h |
| 3 — Flowise Flows | 7 AgentFlow V2 flows, export JSON, import script | 3.0 – 4.5 h |
| 4 — Thin MCP Adapter | Python adapter, .vscode/mcp.json, end-to-end test | 0.75 – 1.0 h |
| 5 — Smart Routing | Routing prefs, Condition Node wiring, `/models prefer` | 0.75 – 1.0 h |
| 6 — Control + Concurrency | pause semantics, stop warnings, concurrent test, error branches | 1.0 – 1.5 h |
| **Total** | | **7 – 10 h (realistic floor: 8.5 h)** |

Estimate assumes: Claude Sonnet 4.6 or better, no blocking approvals, no implementation
issues. The realistic floor of 8.5 h reflects that Flowise AgentFlow V2 JSON schema is
partially undocumented and requires iterative verification even without errors.

---

## 10. Open Decisions

The following decisions must be resolved before or during the indicated phase.
Unresolved decisions in Phase 1–2 block later phases.

---

### Open Decision 1 — HITL Question Channel

**Needed by:** Phase 3 (delegate flow design)

**Question:** When a delegate pauses with a question, where does the user answer it?

| Option | UX | Build complexity |
|---|---|---|
| **Flowise web UI** (port 3000) | Switch to browser tab, answer in Flowise chat thread | None — this is native Flowise behavior |
| **VS Code via MCP polling** | Stay in VS Code; `/status` surfaces pending questions; answer via `/start --answer` | Medium — adapter polls, surfaces question as tool response |

**Recommendation:** Start with Flowise web UI (zero build cost). Add VS Code polling in a
later iteration if the context switch is disruptive.

---

### Open Decision 2 — Plan Reference Format

**Needed by:** Phase 3 (delegate flow Start Node input type) and Phase 4 (MCP tool schema)

**Question:** What does `plan_ref` in `/delegate` point to?

| Option | Pros | Cons |
|---|---|---|
| **File path** | Natural for project work; Claude can write the plan file first | Delegate must have file read access; path must be absolute or relative to mount |
| **Plan ID** (from `/plan`) | Structured; links delegate to a tracked plan record | Requires `/plan` to always precede `/delegate`; more rigid workflow |
| **Inline text** | Simplest for ad-hoc delegation | No traceability; large payloads in MCP tool call |

**Recommendation:** Support both file path and plan ID. If `plan_ref` starts with `/` or
`./` treat as path; otherwise treat as plan ID. Inline text deferred.

---

### Open Decision 3 — File Operation Scope Per Delegate

**Needed by:** Phase 3 (delegate flow tool configuration)

**Question:** Should each delegate be restricted to a specific project subdirectory?

Without restriction, the Agent Node has write access to everything under `~/Projects`.
A runaway or misrouted delegate could overwrite unrelated projects.

| Option | Safety | Flexibility |
|---|---|---|
| **System prompt only** | Low — model can ignore instructions | High |
| **`scope` parameter in tool call** | Medium — enforced in Flowise tool definition | Good — caller sets scope explicitly |
| **Derive scope from plan_ref path** | Medium-high — automatic, no extra param | Works only when plan_ref is a file path |

**Recommendation:** Add optional `scope` parameter to `delegate` tool. If not provided,
derive from the directory containing the `plan_ref` file. Warn user if scope is not set.

---

### Open Decision 4 — Ollama Concurrency Expectation

**Needed by:** Phase 1 (documentation / expectation setting)

**Observation:** Ollama processes one request at a time per loaded model. Multiple
concurrent delegates using the same model alias will queue at Ollama — they interleave,
not truly parallelize. This is not a bug but must be documented.

**Options to address if this becomes a bottleneck:**

| Option | Concurrency | Complexity |
|---|---|---|
| Accept queue behavior | None | None |
| Use different model aliases per delegate | Partial | Low — just assign different aliases |
| Replace Ollama with vLLM | True parallelism | High — significant stack change |

**Recommendation:** Document queue behavior now. If Phase 6 concurrency testing shows
unacceptable throughput, evaluate different alias assignment before considering vLLM.

---

### Open Decision 5 — Pause Semantics

**Needed by:** Phase 6 (pause flow implementation)

**Observation:** Flowise has no external API to suspend a running execution mid-step.
True pause requires the delegate flow to check a flag at each loop iteration.

**Proposed behavior:**
- `/pause <id>` sets `delegates.status = 'pause_requested'` in PG
- At the top of each delegate loop iteration, a Custom Function Node checks this flag
- If `pause_requested`: flow sets HITL node as next step (surfaces to user as "paused")
- If user resumes via `/start`: flag cleared, loop continues

**Risk:** A delegate deep in an LLM call or file write will not pause until that step
completes. Worst case latency before pause takes effect: one full agent iteration.

**Decision needed:** Is this acceptable, or does `/pause` need to be redefined as
"stop after current step" (effectively a graceful stop, not a true pause)?

---

### Open Decision 6 — Stop Behavior and Partial Writes

**Needed by:** Phase 6 (stop flow implementation)

**Question:** When `/stop` terminates a delegate, should it attempt to roll back partial
file writes, or just warn the user?

| Option | Safety | Complexity |
|---|---|---|
| **Warn only** | Low — user must inspect files manually | None |
| **Log ops and warn** | Medium — `file_ops_log` shows what was touched | Low — already in schema |
| **Git stash on stop** | High — automatic rollback via git | Medium — requires git in the delegate tool set |

**Recommendation:** Log all file operations to `file_ops_log` (already in schema). On
stop, return the log in the Direct Reply so the user knows exactly what was touched.
Git stash deferred to a future iteration.

---

### Open Decision 7 — PostgreSQL Exposure to MCP Adapter

**Needed by:** Phase 4 (adapter implementation)

**Question:** The thin MCP adapter needs direct PostgreSQL access for `/status` fast reads.
This means port 5432 is exposed to localhost from the Podman pod.

**Considerations:**
- Acceptable for local development; not acceptable if the pod is ever exposed to a network
- Credentials must come from environment variables, never hardcoded
- Alternative: add a `/status` REST endpoint to Flowise via a Custom Function Node that
  returns the PG query result as JSON — no direct PG exposure needed

**Recommendation:** Use the Flowise REST approach (status flow as the data source) rather
than direct PG exposure. Simpler security posture; fits the "MCP proxies to Flowise" model.
Revisit direct PG access only if status polling latency becomes a problem.

---

### Open Decision 8 — `/plan` Output Persistence

**Needed by:** Phase 3 (plan flow implementation)

**Question:** When `/plan` completes, where is the output written?

| Option | Notes |
|---|---|
| `plans` table only | Queryable; no file clutter |
| File in project directory | Visible to Claude in VS Code context; natural for review |
| Both | Most complete; slightly more flow complexity |

**Recommendation:** Write to both. Plan flow creates `{project_dir}/.delegate/plans/{plan_id}.md`
and inserts into `plans` table. File is the human-readable artifact; table is the
machine-queryable record.

---

### Open Decision 9 — VS Code MCP Scope

**Needed by:** Phase 4

**Question:** Should `.vscode/mcp.json` be workspace-scoped or user-profile-scoped?

| Scope | Effect |
|---|---|
| Workspace (`.vscode/mcp.json`) | Tools available only in this workspace; can be checked into source control; team-shareable |
| User profile | Tools available in all workspaces; no source control; personal only |

**Recommendation:** Workspace-scoped. Check into source control with `input:` variable
references for all credentials (no secrets in the file). Each project repo gets its own
copy, which allows per-project flow ID overrides.

---

### Open Decision 10 — Delegate File Operation Audit

**Needed by:** Phase 3 (delegate flow design)

**Question:** Should delegates log every file read and write to `file_ops_log`?

Logging every operation enables the stop-warning behavior in [Open Decision 6](#open-decision-6--stop-behavior-and-partial-writes)
and provides an audit trail. The cost is additional Custom Function Node calls in the
delegate loop, and `file_ops_log` growing large for long-running delegates.

**Recommendation:** Log writes always. Log reads only when the `scope` parameter is set
(to detect out-of-scope read attempts). Truncate log entries to path + timestamp + op type
only (no file content).

---

*Last updated: 2026-06-09*
