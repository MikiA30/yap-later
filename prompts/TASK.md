# Implement one Yap Later task

Resolve the supplied local Txxx key from docs/TICKETS.md. Its mapped GitHub issue in `MikiA30/yap-later` is recorded as `GitHub issue: #N`. Check required dependencies are integrated; draft status requires reviewing unsettled decisions before claiming.

Claim it: set the issue's label to `status:in-progress` and comment with the session identifier; update `Status:` in docs/TICKETS.md in the same PR. Branch `miki/<issue#>-short-desc` from the current `origin/main`. Never fall back to the old project remote.

Explain scope, implement the task, and run meaningful checks for its acceptance conditions. Coordinate changes to shared contracts/project files. Preserve user edits and unfinished work. Save focused commits crediting only the user. A check not run must remain unverified.

Update the tracker with behavior, checks, device evidence, limitations, and next action. Device-dependent tasks are not complete from simulator/API mocks. Push the branch and open a PR with `Closes #<issue>`, set `status:review`, and merge with a merge commit once checks pass and the user has agreed to merges.
