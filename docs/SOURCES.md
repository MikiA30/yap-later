# Sources and evidence limits

Reviewed during the pivot discussion on November 15, 2026. Recheck versions when selecting a runtime.

- User's pasted ChatGPT conversation: on-phone reminder flow; corrected iPhone 17 Pro/256 GB; proposed typed-first approach and later voice. User named the app VocaLedger (renamed Yap Later on 2026-11-15) and requested a fresh setup.
- Bonsai 4B MLX card: https://huggingface.co/prism-ml/Ternary-Bonsai-2-4B-mlx-2bit — 1.87 GB weights including vision tower; documented Python mlx-vlm support. Not a measured iPhone memory figure or proof of Swift runtime compatibility.
- Bonsai backend support: https://github.com/PrismML-Eng/Bonsai-demo/blob/main/BACKEND-SUPPORT.md — exact format/transform/runtime versions matter; Metal backend support alone is not a validated iPhone app.
- Prism maintainer on iPhone MLX Swift: https://github.com/PrismML-Eng/Bonsai-demo/issues/85 — general direction, not verification of this exact model/app/device combination.
- Apple EventKit store and permission: https://developer.apple.com/documentation/eventkit/ekeventstore
- Apple reminder and alarm APIs: https://developer.apple.com/documentation/eventkit/ekreminder and https://developer.apple.com/documentation/eventkit/ekalarm
- Claude project skills: https://code.claude.com/docs/en/skills
- Interview skill: https://github.com/23jmo/jmo-skills/blob/6082bf2c472857d6cfda48995ab985b69345aac6/skills/interview/SKILL.md — unchanged vendored source; license beside the installed skill.

Do not confuse Bonsai Image 4B (image generation) with the Bonsai 2 language/vision model used to interpret reminder requests.
