# Evaluation

`requests.json` holds synthetic sentences and the outcome the app should reach after validation, with a fixed reference clock so relative dates are repeatable. The check that runs on the device is in `app/YapLater/Services/Inference/InterpreterEval.swift`; launch the app with `YAP_EVAL=1` to run it (see `docs/COMMANDS.md`).

Results are in [`results/`](results/). Each report names the model file and the time taken per sentence. The sentences are made up; no real spending or reminders are stored here.
