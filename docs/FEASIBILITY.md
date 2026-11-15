# Feasibility gates

All gates begin **NOT RUN**. A compiled simulator build, Mac model response, or screenshot is insufficient for a gate requiring real iPhone behavior.

| Gate | Task | Evidence | Status |
|---|---|---|---|
| G0: device launch | T001 | iPhone 17 Pro (iPhone18,1), iOS 26.6.2, Personal Team signing, launched 2026-11-15 03:43 EST | **PASS** |
| G1: local model | T002, T016 | Ternary Bonsai 2 4B Q2_0 GGUF (1,212 MB) via llama.cpp b12405 xcframework, Metal, grammar-constrained JSON. 23/23 on the built-in eval (including 3 reminder sentences), median 1.3 s, load 0.2 to 1.6 s (`eval/results/bonsai-2-4b-iphone17pro-2026-11-15.txt`). 2B Q2_0: 12/20, about 0.7 s. The phone was online during these runs | **PASS on device; offline run user-observed (G3)** |
| G2: nudge notification | T003 | The user saw the nudge notification on the locked iPhone, 2026-11-15 about 08:20 EST. Focus settings were not noted | **PASS (user-observed)** |
| G3: full offline loop | T011 | The user ran the app in airplane mode on the iPhone, 2026-11-15 about 08:20 EST, and reported that the tests I listed (ramble, reminder, airplane-mode run) worked. Latencies for the offline run were not recorded; online latencies are in G1 and G4 | **PASS (user-observed)** |
| G4: on-device speech | T020 | WhisperKit 1.1.1, openai_whisper-small copied to the phone; live yaps by the user transcribed in 0.25 to 0.85 s; number-word prompt verified with synthetic speech and the user's voice. The phone was online | **PASS on device; offline run user-observed (G3)** |
| Reminders (T024) | T024 | Spoken reminder on the iPhone, 2026-11-15 about 07:55 EST: the card appeared, Save wrote it, and the user saw it in the Reminders app with its alert set. The phone was online. Delivery of the alert at its time was not recorded | **PASS on device (creation); alert delivery not observed** |
| Ramble (T021) | T021 | Four test rambles (9 parts) run through Bonsai 2 4B on the iPhone via the debug probe: every part read correctly. Not yet tried with a live voice | **PASS on device (typed probe); live voice NOT RUN** |
| Mac, Wi-Fi off (T026) | T026 | Native macOS build of the same app (ad hoc signed, llama.cpp macOS slice, WhisperKit), 2026-11-15 08:28 EST: Bonsai 2 4B 23/23 on the built-in eval, median 558 ms, load 4.4 s; WhisperKit synthetic speech test correct. Repeated at 08:31 with all network access denied to the app's process (`sandbox-exec` with `deny network*`): eval 23/23, median 563 ms, speech test correct. Not yet done: a live microphone yap in the window, and a run with the Mac's Wi-Fi switched off | **PASS for model and speech with network denied; live mic and Wi-Fi-off run NOT RUN** |
| Argmax voice (T030) | T030 | TTSKit 1.1.1 with Qwen3-TTS 0.6B on the Mac, 2026-11-15 08:38 EST: loads from disk in about 2 s with network access denied; first audio 0.2 to 0.5 s for the ask-back question and a nudge. Nobody has listened to judge the quality yet. On the iPhone the model is copied and the code is installed but disabled (marker file `Documents/tts/enabled` absent); the phone was locked, so the voice and the microphone-after-voice check have not run there | **PASS on Mac (timing only); iPhone NOT RUN** |
| G1-fallback: Foundation Models | T016 | Compiles and is wired as a labeled fallback; not exercised on the phone because Bonsai is present | NOT RUN |

Findings worth keeping:

- Bonsai 2 is a `qwen35` architecture. llama.cpp could not trim its memory in place between requests (`llama_memory_seq_rm` on a partial range), which leaked the previous answer into the next request. The app now restores a saved snapshot of the memory after the fixed prompt prefix (869 tokens, 77 MB) for every request.
- Putting the examples in the prompt as earlier chat turns, instead of inside the instructions, took the 2B from 8/20 to 12/20.
- Whisper writes "six fifty" as "650" unless prompted with spelled-out amounts.
- After each fresh install the first WhisperKit load is slow (Core ML recompiles); later launches are fast.

## G1 approach

Ask the sponsor for a known working iOS starter. Try a supported 2B or 4B artifact; select based on integration reliability and measured quality. A smaller unsupported model is not a solution to a missing runtime. Record whether the pack includes a vision tower and whether the runtime loads it for text-only use.

The documented 4B MLX pack is 1.87 GB on disk; this is not peak RAM. Its Python `mlx-vlm` recipe is not an iOS deployment recipe. Possible Swift/MLX or embedded llama.cpp paths must be verified for the exact artifact and Bonsai transformations. See `docs/SOURCES.md`.

Evaluate short explicit requests, relative times, ambiguity, cancellation, several repeated generations, and warm versus cold start. Record runtime support for structured output and thinking control rather than assuming generic API parameters work.

## G2 approach

Use a hardcoded draft first, independent of the model. Confirm EventKit access with an appropriate usage description, a writable reminder list, an explicit alarm, and local save. Observe delivery separately from successful persistence. Check Reminders notification permission/settings and Focus if an alarm does not appear. The app should not independently schedule a second local notification for the same reminder without a deliberate product decision.

Test offline after required setup/assets are present. Airplane mode alone may leave Wi-Fi enabled: verify both radios' state. Record test-reminder identifiers so the user can clean up test data deliberately.

## Result template

Date/time and tester:
Device and iOS:
App commit/build:
Model ID, revision, format, file size:
Runtime revision/version:
Input and current-time/time-zone context:
Network state and Mac disconnected:
Cold/warm loading and response timings:
Peak memory / method or unavailable:
Observed output, reminder persistence, and notification result:
Failure and fallback:
Evidence location:
Gate verdict: PASS / FAIL / BLOCKED / NOT RUN
Next action:

Store detailed measurements under `eval/results/` and link them here. Keep personal reminder content out of committed evidence.
