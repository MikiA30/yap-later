# Feasibility gates

All gates begin **NOT RUN**. A compiled simulator build, Mac model response, or screenshot is insufficient for a gate requiring real iPhone behavior.

| Gate | Task | Required evidence | Status |
|---|---|---|---|
| G0: device launch | T001 | Physical iPhone model/iOS, signing path, successful signed app launch | NOT RUN |
| G1: local model | T002 | Exact checkpoint/revision/quantization/runtime, offline text output, cold/warm latency, memory if measurable, repeated requests | NOT RUN |
| G2: Apple Reminder | T003 | Permission result, writable list, saved reminder with due date and alarm, locked-phone alert with networking off | NOT RUN |
| G3: full offline loop | T011 | Cold launch, fresh typed input, valid reviewed draft, save, and observed alert with no Mac/cloud dependency | NOT RUN |
| G4: on-device speech | T020 | WhisperKit package/model version, three spoken reminders transcribed offline on the iPhone, latency | NOT RUN |
| G1-fallback: Foundation Models | T016 | Only if G1 fails by 06:30: Apple Intelligence enabled, structured proposal returned offline on the iPhone | NOT RUN |

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
