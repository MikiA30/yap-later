# Proposed model contract

`reminder-proposal.schema.json` describes a structured model proposal, not a permission to write a reminder. Fixtures are synthetic examples. Their fixed calendar date is intentional and must be evaluated against a fixed test clock; it is not a live reminder to create today.

The schema does not enforce all semantic constraints. T004/T006 must add cross-field checks, calendar validity, time-zone/DST behavior, reference-clock resolution, unsupported-intent checks, and explicit user confirmation. See `docs/CONTRACTS.md`.
