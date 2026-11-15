---
name: swiftui-motion
description: Yap Later's motion and visual-craft guide for native SwiftUI on iOS 26. Use when building or reviewing any Yap Later screen, transition, animation, loading state, haptic, or visual style, or when the user asks for animations, transitions, polish, or "not AI slop". Translates proven web-animation practice (GSAP timelines, staggering, performance, reduced motion) into SwiftUI APIs. Never recommend GSAP, Lenis, React, or web views for this app.
---

# SwiftUI motion for Yap Later

Yap Later is a native SwiftUI app (Xcode 26.6, iOS SDK 26.5, iPhone 17 Pro). Every animation here is SwiftUI or UIKit. Do not add web views or JavaScript animation libraries.

## 1. Motion explains state; it never invents it

Each animation answers one question for the user: *where did this come from, what changed, or what happens next?* If it answers none, leave it out.

Yap Later rules on top of that:

- **No success motion before success.** Play the Save confirmation, haptic, and checkmark only after EventKit's `save` returns without error. Animate "Saved to Reminders" and "Alert verified" as separate states, because they are separate facts (see AGENTS.md).
- **Show inference honestly.** While the model works, show that it is working and offer Cancel. Use no fake progress bars, typewriter effects that pretend the model is "typing", or shimmer skeletons for content that isn't loading.
- **The preview stays still while you review it.** Once the editable confirmation card has settled, nothing on it moves unless the user changed it. A field the user just edited or clarified may change once (e.g. `numericText` on the time). It should not loop or pulse.
- **Destructive or committing actions do not bounce.** Use bounce for small delights, such as a symbol confirming a save. Do not use it on the Save button, errors, or permission prompts.

## 2. Motion tokens: one vocabulary for the whole app

Define animations once in a `Motion` namespace and use only these. Ad-hoc `.easeInOut(duration: 0.3)` scattered through views is how an app starts to feel generic.

```swift
enum Motion {
    static let quick   = Animation.snappy(duration: 0.22)          // taps, toggles, small state
    static let move    = Animation.smooth(duration: 0.38)          // layout, cards, screen content
    static let present = Animation.spring(duration: 0.5, bounce: 0.12) // card arrival, sheet-like reveals
    static let delight = Animation.bouncy(duration: 0.45, extraBounce: 0.05) // only confirmed success
    static func stagger(_ index: Int, step: Double = 0.035, cap: Int = 6) -> Double {
        Double(min(index, cap)) * step
    }
}
```

Springs are interruptible and keep velocity when retargeted. Prefer them over timing curves for anything the user can interrupt. Tune the values on the device, not in the simulator. Record the final values in the code, not just in chat.

## 3. Web practice translated to SwiftUI

The concepts come from GreenSock's official GSAP skills (MIT) and from the categories in React Bits. The APIs below are SwiftUI's own.

| Web idea | SwiftUI tool | Notes |
|---|---|---|
| Tween `gsap.to` | `withAnimation(Motion.move) { state = … }` or `.animation(Motion.move, value: x)` | Animate state, not views. Scope it with `.animation(_:body:)` so unrelated changes don't animate |
| Timeline + position parameter, labels | `KeyframeAnimator` (parallel `KeyframeTrack`s, each a sequence) or `PhaseAnimator` (discrete named phases) | Do not chain `DispatchQueue.main.asyncAfter` or `Task.sleep` to sequence steps. GSAP's own rule is "timelines over delays" |
| `onComplete` | `withAnimation(_:completionCriteria:_:completion:)` | Use `.logicallyComplete` to hand off to the next step without waiting for spring settle |
| `stagger` | Per-index delay: `Motion.move.delay(Motion.stagger(i))` | Cap it. Six items × 35 ms is the most a user should wait |
| Flip plugin / shared element | `matchedGeometryEffect`; `.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(sourceID:in:))` | Use for the input → preview card handoff so the card grows out of what was typed |
| `autoAlpha` | Conditional view + `.transition(...)`, or `.opacity` + `.allowsHitTesting(false)` | An invisible view must not take taps |
| SplitText, Blur Text, Rotating Text | `.transition(.blurReplace)`, `.contentTransition(.numericText(value:))`, `.contentTransition(.interpolate)`, `TextRenderer` for per-line effects | `numericText` is ideal for times and dates changing during clarification |
| Count Up | `.contentTransition(.numericText(value:))` inside `withAnimation` | |
| ScrollTrigger / scroll reveal | `.scrollTransition { content, phase in … }`, `.visualEffect { … }`, `onScrollGeometryChange` | Use sparingly. Yap Later has little scrolling |
| `quickTo` (pointer follower) | Drive state from `DragGesture` with `.interactiveSpring()`; release with `Motion.present` | Keep gesture-driven views on transforms |
| `gsap.matchMedia` reduced motion | `@Environment(\.accessibilityReduceMotion)` | Reduce Motion means swap movement and scale for crossfades. Do not just turn animation off |
| `will-change`, transforms over layout | `.offset`, `.scaleEffect`, `.rotationEffect`, `.opacity`, `.blur` before frame/padding changes; `.drawingGroup()` only for proven-heavy layered drawing | Animate layout only when the layout change itself is the meaning |
| Kill/cleanup tweens | Tie repeating effects to view lifetime and state; stop them when the state ends | Nothing should keep animating off screen or after inference ends |

Also available, and native to iOS:

- **SF Symbols:** `.symbolEffect(.bounce, value:)`, `.symbolEffect(.pulse)` while waiting, `.contentTransition(.symbolEffect(.replace))` when an icon changes meaning (e.g. mic → waveform → checkmark).
- **Haptics:** `.sensoryFeedback(.success, trigger:)` after a confirmed save, `.selection` for picker changes, `.warning` or `.error` for a blocked save. Reserve haptics for these moments; never add them to every tap.
- **Liquid Glass (iOS 26):** system controls, toolbars, and sheets adopt it automatically, so start there. Use custom `.glassEffect()`, `GlassEffectContainer`, and `.glassEffectID(_:in:)` only for a deliberate floating control or morph. [Unverified] Confirm exact signatures by compiling against SDK 26.5 before relying on them.
- **Mesh and gradients:** `MeshGradient` can carry a calm, slow ambient state during inference. It must not be the app's personality by default.

## 4. Not AI slop: visual craft checklist

Reject a screen that has any of these:

- Purple-to-blue gradients, glows, particles, or glassmorphism used as the only design idea.
- Every element fading or sliding in on appear. Entrance motion is for content that *arrived*, not for the whole screen each time.
- Generic card grids, emoji as icons, centered hero text with a gradient word, or placeholder copy ("Your AI-powered assistant").
- Inconsistent corner radii, spacing, or font weights. Use one spacing scale (4/8/12/16/24/32) and one corner radius per surface type, with `ContainerRelativeShape` or concentric radii inside glass.
- Low contrast in dark mode, or text that breaks at large Dynamic Type sizes.

Prefer:

- A clear typographic hierarchy in SF Pro: one large, confident element per screen (the reminder title on the preview), with secondary text in `.secondary`.
- Specific, human copy: "Tomorrow, 6:00 PM · America/New_York", not "Date: 2026-11-16T18:00".
- Restraint: one signature moment per flow (e.g. the input morphing into the confirmation card), with everything else quiet and fast.
- System semantics first (`List`, `Form`, `DatePicker`, `.toolbar`, sheets), then custom polish on top.

## 5. Performance and correctness

- Run inference off the main actor. A janky animation during inference usually means main-thread work, not a bad curve.
- Avoid animating large view trees whose identity changes. Give stable `id`s and keep animated state small.
- Do not retrigger `onAppear` animations on every re-render; key them to a state value.
- Check with Instruments (SwiftUI template, Animation Hitches) on the iPhone 17 Pro, at 120 Hz ProMotion.

## 6. How to verify a motion change

1. Build and run on the device. The simulator is fine for layout, not for feel.
2. Check it with Slow Animations (Simulator: Debug → Slow Animations), so the sequencing is visible.
3. Turn on Settings → Accessibility → Motion → Reduce Motion and confirm every flow still reads clearly.
4. Interrupt it: tap Cancel or edit mid-animation. Nothing should jump, duplicate, or save.
5. Check dark mode, the largest accessibility text size, and a 30-character title.
6. Record a short screen capture for review. Keep recordings out of Git (AGENTS.md).

Report what you saw on the device separately from what you only wrote.
