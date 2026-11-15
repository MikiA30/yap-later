# Build Yap Later's first runnable shell

Read AGENTS.md, the spec, plan, architecture, contracts, commands, and T001. Resolve only decisions needed to create the actual iOS project. Use SwiftUI unless kickoff establishes another native choice.

Implement T001: typed entry → visibly labeled mock interpretation → editable preview/cancel. Introduce narrow service boundaries so real inference and EventKit can replace mocks. Do not claim a mock save created an Apple Reminder. No real reminder write is required for the skeleton; T003 proves it explicitly.

Establish project/scheme, device/signing prerequisites, responsive states, and actual build/run commands. Build and launch on the available target, reporting simulator versus physical iPhone separately. Preserve privacy and signing settings; never fabricate a team ID. Ask for physical-device interaction only when necessary, after finishing the independent build work.

Record results and remaining gaps in COMMANDS and FEASIBILITY. G0 passes only on a physical-device launch. Save/integrate the foundation before feature workers split off. Do not implement the entire backlog in this command.
