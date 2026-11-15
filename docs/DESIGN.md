# Design

**Mood:** playful and bold. Money apps are usually gray and anxious; this one should feel like a friend you can blurt things to.

- **Paper and ink.** Warm cream background (`Theme.paper`), near-black ink with a violet tint. Dark mode is a warm espresso brown with cream text, not black.
- **One loud color.** Hot orange (`Theme.brand`) is reserved for the thing you press and the app speaking to you (the ask-back bubble).
- **A color per category.** Nine category colors, kept quieter than the orange, so the ledger and budgets read at a glance. Yellow means "running low", red means "spent or over"; green is never used for a warning.
- **Stickers and chunky buttons.** Cards sit on a solid edge instead of a soft shadow; buttons sink onto their edge when pressed. Depth comes from offset, not blur.
- **Big rounded numerals.** SF Rounded, black weight. The week's total is the largest thing on screen.
- **Motion with a reason.** The total and "left" amounts roll with `numericText`; a new entry pops up from the dock; the budget bar slides; the nudge pushes content down rather than covering it; the waveform follows the real microphone level. Success feedback (haptic, toast) happens only after the entry is stored. The weekly total is a thick number you can spin; a budget card grows, fills and settles when an expense lands in it; the charts draw themselves from stored entries. Reduce Motion swaps movement for fades. Tokens live in `DesignSystem/Motion.swift`.

Tokens: `app/YapLater/DesignSystem/Theme.swift`. Components: `Components.swift`. Icon: `scripts/make_icon.py`.

Not yet checked on a device: the largest Dynamic Type size and a full VoiceOver pass.
