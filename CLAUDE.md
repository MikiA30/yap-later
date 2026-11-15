@AGENTS.md

# Claude Code: Yap Later

This is the Yap Later repository. Load the context and phase from `AGENTS.md`; ignore old ket-lite assumptions from another conversation.

| Command | Output or action |
|---|---|
| `/interview` | Resume the seeded `.plans/yap-later-spec.md` using Johnathan Mo's skill and `prompts/INTERVIEW.md` |
| `/kickoff` | Reconcile the spec into plan, architecture, contracts, feasibility gates, and decisions |
| `/tickets` | Review/revise the existing draft backlog without losing stable keys or progress |
| `/skeleton` | Implement T001: a minimal signed iOS shell and clearly labeled mock flow |
| `/task T002` | Work on one ready task; this example is the real-device model proof |
| `/sync` | Integrate current work using THIS repository's Git configuration |
| `/team-status` | Report demonstrated behavior, blockers, ready tasks, and next action |

For `/interview`, first read the project brief, event context, `docs/DECISIONS.md`, `prompts/INTERVIEW.md`, and `.plans/yap-later-spec.md`. Ask the remaining high-impact questions in the main conversation. Preserve the user's answers and update that exact spec file as you go. The original skill is unchanged; project-specific behavior is supplied here and in AGENTS.md.

The current setup is ready for a focused interview and kickoff. Draft tickets already exist to accelerate planning; none represent completed implementation. Device access, signing, sponsor iOS runtime compatibility, permission behavior, and offline alert delivery remain unverified.
