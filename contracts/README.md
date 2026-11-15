# Contracts

`money-proposal.schema.json` is the JSON the on-device model returns for a spoken sentence; `reminder-details.schema.json` is the second step for reminders. `fixtures/` holds one example of each case. The Swift types are `MoneyProposal` and `ReminderDraft` in `app/YapLater/Domain/`; the grammars that force this shape are in `BonsaiInterpreter.swift`. See `docs/CONTRACTS.md`.
