# Yap Later interview context

Use Johnathan Mo's original `.claude/skills/interview/SKILL.md`. This file supplies project context, not a replacement interview skill.

Read AGENTS.md, ideation/PROJECT_BRIEF.md, ideation/EVENT.md, docs/DECISIONS.md, and the seeded .plans/yap-later-spec.md. Carry forward known answers. Ask 1–3 connected questions at a time, keeping the interview in the main conversation. Save answers incrementally into the spec; mark proposals versus user decisions.

Start with the actual remaining time, typed-first versus required voice, sponsor iOS starter availability, and physical device/signing access. Then settle the first user/problem, single-reminder scope, exclusions, language, ambiguity handling, writable list behavior, and acceptable latency. Use examples: “tomorrow at six,” “in one minute,” “every Friday,” and a request containing two tasks.

The user wants a fully working native iOS app with distinctive transitions and animation, not generic "AI slop" (2026-11-15). Once the core flow is settled, ask briefly about the look and feel: the one signature moment (e.g. the typed request morphing into the confirmation card), the mood (calm and precise versus playful), what happens visually while the model thinks, and the Save moment. Use `.claude/skills/swiftui-motion/SKILL.md` for options and plain-language explanations; record the answers as design decisions with acceptance checks.

Do not repeatedly ask the confirmed name or corrected phone. Do not turn this into a broad productivity platform or force an hour. Depth should uncover blockers and the smallest viable demo. Stop for a concise scope review when critical product decisions are explicit; record runtime/performance questions as experiments, not interview answers. Keep voice provisional until the user confirms its priority.

Save to the absolute path of .plans/yap-later-spec.md in this repository. Do not run kickoff, publish tickets, or build the app just because the interview finished.
