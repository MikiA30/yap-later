# Demo and submission checklist

> **Superseded in part (2026-11-15 03:35):** the product pivoted to a voice-first local expense tracker. `.plans/yap-later-spec.md` and `docs/TICKETS.md` are authoritative; this file still describes the earlier reminders flow until its ticket rewrites it.

- [ ] Confirm the actual cutoff, demo duration, and required integrations.
- [ ] Record device/iOS, app commit, exact model/runtime versions, and setup steps.
- [ ] Download/provision everything before the offline test.
- [ ] Cold-launch on the iPhone with Wi-Fi and cellular disabled and the Mac disconnected.
- [ ] Enter a fresh one-minute reminder; record inference time and inspect the exact preview.
- [ ] Save once; verify the actual Apple Reminder, its list, due time, and alarm.
- [ ] Lock the phone; observe the notification. Note Reminders notification/Focus settings used.
- [ ] Show one ambiguous request asking a question instead of silently saving.
- [ ] Verify cancel, edit after interpretation, repeated Save, denied permission, and failure recovery.
- [ ] Check no features described as real still use mocks.
- [ ] Rehearse a concise explanation: the user problem, what AI interprets, what runs on-phone, and the real outcome.
- [ ] If capturing a backup recording, label it as a recording and avoid private reminder content.
- [ ] Prepare the required README, repository, model attribution, evidence, project description, and submission links.
- [ ] Show the signature transition (request → confirmation card) and the Save moment on the real device.
- [ ] If voice landed (T012), show one spoken request in airplane mode.
- [ ] Pitch script in docs/PITCH.md rehearsed against the clock; backup video ready (T023).
- [ ] Repository visibility matches the rules; README has real measurements only (T022).
- [ ] Submit before the confirmed deadline and verify confirmation.

Voice, multiple reminders, recurrence, and interface polish are optional only after the core is reliable. A model extraction demo without an actual Reminder/alarm is an intermediate milestone, not this demo's definition of done.
