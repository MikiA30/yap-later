# Yap Later ticket review

Read the spec and working docs. A concrete draft backlog already exists in docs/TICKETS.md: revise it instead of replacing it wholesale. Keep stable keys, dependency integrity, and existing progress. Add only the tasks needed by the agreed demo.

Each task needs one bounded behavior, dependencies, allowed files, an owner/session, meaningful acceptance evidence, and status. Verify missing dependencies and cycles with scripts/check_setup.py. Do not mark draft work ready while essential scope remains unresolved. G0/G1/G2 are separate gates; mock work must not satisfy real-device acceptance.

Keep optional voice/model comparisons out of the required demo dependencies unless the user explicitly changes scope. Separate local task keys from remote issue numbers. The tracker is GitHub issues in `MikiA30/yap-later`; publish new tickets with `scripts/create_issues.py` and keep `GitHub issue: #N` in each ticket. Never use the old ket-lite issue tracker.
