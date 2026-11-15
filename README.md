# Yap Later

An iPhone app that turns a natural-language request into a reviewed Apple Reminder, with interpretation on the phone and no runtime dependency on a Mac or cloud service.

**Status:** fresh planning starter. The specification and backlog are seeded from the pivot conversation; implementation and device evidence have not started here.

## Start

Open [START_HERE.md](START_HERE.md), then start a fresh Claude conversation from THIS folder:

```sh
cd '/Users/mikiyasasmamaw/Documents/ChatGPT/VocaLedger'
claude
```

Inside Claude, enter `/interview`. Johnathan Mo's published skill is already installed locally under that short name. Read the saved spec, then run `/kickoff` and `/tickets`. After the draft plan is settled, run `/skeleton`; then prioritize `/task T002` and `/task T003` for the two device proofs.

The old ket-lite project is preserved separately. This repository starts with no remote or GitHub issues. Stable local ticket keys are not issue numbers.

## Files to know

| File | Purpose |
|---|---|
| `ideation/PROJECT_BRIEF.md` | Known product and device context |
| `.plans/yap-later-spec.md` | Seeded spec and unresolved interview decisions |
| `docs/PLAN.md` | Smallest demo and sequence |
| `docs/FEASIBILITY.md` | Device proof gates and result template |
| `docs/ARCHITECTURE.md` | Proposed Swift modules and ownership |
| `docs/CONTRACTS.md` | Interpretation, validation, confirmation, and save boundaries |
| `contracts/reminder-proposal.schema.json` | Proposed model-output format |
| `docs/TICKETS.md` | Concrete draft tasks and dependencies |
| `docs/COMMANDS.md` | Verified commands versus unverified app setup |
| `docs/DEMO.md` | Rehearsal and submission checklist |
| `docs/PREPARATION.md` | Provenance and work record |

The `.claude/skills/interview/` skill is copied unchanged with its license. Other slash commands in `.claude/commands/` call portable workflow instructions in `prompts/`. These documents can also guide another coding tool.

Run `python3 scripts/check_setup.py` to check setup consistency. This does not build an app or establish iPhone compatibility.
