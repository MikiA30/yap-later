# Decisions

| Date | Status | Decision / reason |
|---|---|---|
| 2026-11-15 | User | Name the new app VocaLedger and rebuild the setup from scratch |
| 2026-11-15 | User | Target phone is iPhone 17 Pro, 256 GB storage |
| 2026-11-15 | Direction | Fully on-phone reminder interpretation with reviewed creation of Apple Reminders |
| 2026-11-15 | Setup choice | Fresh sibling folder and independent local Git repository; preserve ket-lite separately |
| 2026-11-15 | Carried preference | Use Claude Code and Johnathan Mo's original `/interview` skill; documents stay portable |
| 2026-11-15 | Proposal | SwiftUI native iOS application; typed input first and one reminder at a time |
| 2026-11-15 | Proposal | EventKit owns saved reminders/alarms; no model background loop |
| 2026-11-15 | Open | Exact Bonsai model, quantization, runtime, iOS version, signing team, and measured performance |
| 2026-11-15 | Open | Deadline, required sponsor integrations, voice priority, demo audience, latency target |
| 2026-11-15 | User | Rename the app **Yap Later**; supersedes VocaLedger as the product name. The local folder keeps its old name |
| 2026-11-15 | User | Create a GitHub repository and use it as the ticket system; supersedes "local tickets until a remote is chosen". Private repo `MikiA30/yap-later`, issues with `status:`/`area:`/`priority:` labels and a submission milestone |
| 2026-11-15 | User | Goal: a fully working native iOS app that wins the hackathon, with distinctive transitions and animation, not generic AI-looking UI |
| 2026-11-15 | Proposal | Backlog timed to the last known cutoff (Sun Nov 15, 12:00 EST, unconfirmed): feature freeze 10:00, Bonsai gate hard stop 06:30 |
| 2026-11-15 | Proposal | If Bonsai cannot run on the iPhone by 06:30, fall back to Apple's on-device Foundation Models behind the same interface, labeled as a fallback (T016) |
| 2026-11-15 | Proposal | Voice through Argmax WhisperKit (sponsor) as a parallel should-have lane (T020 → T012); user to confirm whether voice is required for the demo |
| 2026-11-15 | User | **Pivot: money first.** Yap Later is a voice-first, fully local expense tracker with weekly per-category budgets and nudges; reminders/bills and location nudges are stretch. Supersedes the reminders-first direction and the "typed first" proposal |
| 2026-11-15 | User | Deadline 8:30 AM EST today; supersedes the noon-based timeline |
| 2026-11-15 | User | Voice is the hero (WhisperKit must-have); ask back by voice on ambiguity; expenses auto-save with undo; playful and bold look; Action Button trigger; demo week pre-logged through the app |
| 2026-11-15 | User | No AI contributor on commits or PRs: no co-author trailer, no generated-by line |
| 2026-11-15 | Proposal | Fixed categories, USD integer cents, SwiftData, nudge threshold, AVSpeechSynthesizer for spoken questions: see the spec's product rules |
| 2026-11-15 | User | Use the sponsor models: Bonsai 2 (2B or 4B) and Argmax for voice |
| 2026-11-15 | Evidence | Interpreter locked: **Ternary Bonsai 2 4B Q2_0 via llama.cpp b12405** (20/20 on the iPhone eval vs. 12/20 for 2B). Apple Foundation Models stays as a labeled fallback only. Supersedes the 05:15 fallback proposal |
| 2026-11-15 | Evidence | Speech: WhisperKit 1.1.1 with openai_whisper-small and a number-word prompt |
| 2026-11-15 | User | Work in one session, not parallel agents, to conserve usage; Claude may merge its own PRs once checks pass |

Preserve superseded decisions with the replacement and reason. Do not mark a proposal accepted merely because it appears in the draft backlog.
