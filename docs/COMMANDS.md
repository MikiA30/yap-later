# Commands and verification

## Starter

```sh
cd '/Users/mikiyasasmamaw/Documents/ChatGPT/VocaLedger'
python3 scripts/check_setup.py
claude
```

Tracker: `gh issue list -R MikiA30/yap-later --milestone "Hackathon submission"`. Publish new tickets: `python3 scripts/create_issues.py`.

Inside Claude: `/interview`, `/kickoff`, `/tickets`, `/skeleton`, `/task T002`, `/task T003`, `/team-status` as appropriate to the current stage.

`claude plugin validate --strict .claude/skills` and `claude plugin validate --strict .claude/commands` check Claude configuration when that CLI is installed.

## App commands: not established

No Xcode project exists yet. T001 must record the actual project, scheme, destination/device ID, signing setup, build/run/test commands, and which commands were executed. Do not copy ket-lite's macOS build commands or assert that an iOS Simulator validates Metal inference.

| Check | Actual command | Result/evidence |
|---|---|---|
| Build iOS app | TBD in T001 | NOT RUN |
| Install/launch on user's iPhone | TBD in T001 | NOT RUN |
| Unit/contract tests | TBD in T004 | NOT RUN |
| Local model probe | TBD in T002 | NOT RUN |
| Reminder/alert probe | TBD in T003 | NOT RUN |
| Full offline acceptance | Procedure in docs/DEMO.md | NOT RUN |

## Git

The new repository has no remote and no inherited issues. Make an initial reviewed local commit before branching. `scripts/worktree.sh <branch>` creates a separate working copy from local `main` once an initial commit exists. Add a new remote only after the destination is chosen. Local ticket keys remain separate from any GitHub numbering.
