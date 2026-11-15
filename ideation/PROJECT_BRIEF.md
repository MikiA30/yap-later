# Yap Later: supplied context

## Confirmed and adopted context

- [User] Name: **Yap Later** (2026-11-15; replaces the earlier working name VocaLedger). Rebuild the setup from scratch, including interview, kickoff, and tickets.
- [User] Device correction: **iPhone 17 Pro, 256 GB storage**. Do not plan around the earlier iPhone 15 Pro statement.
- [Direction] A fully on-phone app interprets natural-language reminder requests locally and creates actual Apple Reminders after confirmation.
- [Direction] The complete flow should work without Wi-Fi/cellular after setup, including an alert while the phone is locked.
- [Context] The user is pivoting away from a larger ket-lite tutoring project. Preserve that work in its own repository.
- [Context] The user already uses Claude Code and Johnathan Mo's interview skill. Preserve that workflow and portable documents.
- [Context] An existing Bonsai 9B runs on the user's Mac. That is not evidence that the iPhone can load a chosen 2B/4B artifact.

## Proposed small first version

Typed request → local interpretation → clarification if needed → editable title/date/time/list confirmation → Save → Apple Reminder with alarm. One reminder per request. Voice input follows after the typed path works. Confirm this priority in the interview: the name alone does not make voice a first-release requirement.

The model interprets language. Application code validates dates and gates writes. Apple Reminders owns the scheduled reminder after it is saved; no persistent background inference loop is needed.

## First example

“Remind me in one minute to check my homework.” Confirm the exact due time, save, lock the phone, and observe the system alert with Wi-Fi and cellular off.

## Questions that actually change the next step

1. What is the confirmed deadline and available build time now?
2. Is typed-first acceptable, or is voice essential to the submitted demo?
3. Is a sponsor-provided iOS Bonsai starter/runtime available? Which exact checkpoint does it support?
4. Can the iPhone be connected to this Mac and signed/launched from Xcode now?
5. Is the first user a student organizing tasks, or another audience? What makes the demo valuable beyond a single basic reminder?
6. Are single dated reminders enough? Proposed exclusions: recurrence, location triggers, multiple reminders per request, attachments, calendar events, and background listening.
7. Which language, time zone behavior, destination list, and acceptable response time should the first demo use?
