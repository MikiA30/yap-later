# Source

Written for Yap Later on November 15, 2026 (Claude Code, Opus 5.5), after the user asked to evaluate three repositories for animation and UI skills. Original SwiftUI guidance; no source code or skill text was copied.

| Repository | What it is | Used here | Not used, and why |
|---|---|---|---|
| [greensock/gsap-skills](https://github.com/greensock/gsap-skills) at `aed9cfd3277740755f6bfc1155c7aa645403b760` (MIT), the official skills repo for [greensock/GSAP](https://github.com/greensock/GSAP) | Agent skills for the GSAP JavaScript library | Concepts from `gsap-timeline`, `gsap-performance`, and `gsap-core`: timelines over delays, labeled sequencing, stagger, transforms over layout, cleanup, reduced motion | Not installed. The skills teach a JavaScript API, and their descriptions trigger on general animation requests, which would push agents toward GSAP in a native iOS app |
| [darkroomengineering/lenis](https://github.com/darkroomengineering/lenis) (MIT) | Smooth-scroll library for websites | Nothing | iOS scrolling is already native and physically modeled; the repo has no agent skills |
| [DavidHDev/react-bits](https://github.com/DavidHDev/react-bits) (MIT + Commons Clause) | Animated React components; its agent-kit skills are a paid Pro product, not in the repo | Effect categories only (blur/split/rotating text, count up, animated list) as a menu of ideas mapped to native SwiftUI tools | No components ported. The license forbids redistributing the components, including as a ported version |

Update this skill as Yap Later's actual motion design is decided and measured on the device.
