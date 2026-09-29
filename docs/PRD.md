# HIDIT interval timer: Claude Design brief

> Source: [Claude Docs PRD](https://claude.ai/artifact/8ZAdn1RV6QvnJzDbWzmRWA), copied at rev 5 on 2026-09-29, with the HIDIT ladder corrected afterwards. The online doc is the source of truth; update this copy when it changes.

A lightweight iOS and Android interval timer for VO2 max training. It runs HIDIT (High-Intensity Decreasing Interval Training, where work and recovery shrink each step while holding a strict 3:2 work-to-recovery ratio) plus fixed presets. It is used mid-run, so it must be readable at arm's length and in motion. Goal: two taps from open to running, no menus mid-run.

> v1 ships on iOS only (SwiftUI). Android is a later port.

## Visual direction

Quiet, flat and precise, in the [Axis Gray design system](design-system/README.md): warm gray ground, thin type, big wide numerals, concentric hairline circles and one soft red-orange gradient. The timer is the only loud thing on screen. Light mode only. The design uses only the colors of its reference image: grays, white, taupe, black, one red and one orange.

**Color tokens (light only)**

- Ground (screen background): #DBDAD8
- Surface (cards, sheets): #E7E6E3
- Ink (primary text, main action button): #1A1A19
- Muted (secondary text, labels): #5E5B58
- Hairline: rgba(26,26,25,0.16), dashed guides rgba(26,26,25,0.3)
- Taupe (icon buttons, white glyph): #8E8584
- Work (run): #B93A26
- Recover: #4A4746 (graphite)
- Signal (gradient blob and focus dot only): #C4432B
- Ember (second gradient stop, decoration only): #D98A3B

On the run screen the background takes a 12 percent tint of the phase color (red for work, graphite for recover) and the timer takes the full-strength color. The main action is a charcoal pill with white text. Red and orange appear only as the work color and in the decorative gradient.

**Typography:** Michroma, a wide squared display face, sets every number and every heading. Hanken Grotesk sets text. Numbers are the hero, with tabular figures: run timer 84 to 112 pt, get-ready countdown up to 168 pt, finish and summary totals 64 to 80 pt, stats and stepper values 22 to 26 pt. Headings and phase names are uppercase Michroma, 13 to 24 pt. Body is Hanken Grotesk 17 pt light. Labels are Hanken Grotesk 11 pt uppercase in the muted color, 0.06em tracking. Buttons are 20 pt semibold. Both faces are bundled with the app.

**Shape and layout:** continuous (squircle) corners: 20 pt cards, 16 pt buttons, 28 pt for the black summary card, pill for the main action. Flat surfaces, hairline borders, dashed hairlines for list dividers and chart guides, no shadows. 20 pt side margins, single column, left aligned. Thin outline icons used sparingly. Icon buttons are taupe squircles with a white glyph. Direction is shown with a heavy square-cap diagonal arrow. Calm screens (home, get ready, finish, first launch) carry three or four concentric hairline circles and a blurred red-orange gradient at the bottom. The run screen has no decoration.

**Motion:** one meaningful transition, a phase-color cross-fade of about 250 ms at each change. Buttons scale to 0.98 on press. Reduced motion swaps the cross-fade for an instant change.

**Do not use:** neon, flames, lightning bolts, leaderboard chrome, confetti, pure black backgrounds, green or blue phase colors, dark mode.

## Screens

1. **Home:** light greeting on the left, bold weekday with a small date on the right, a taupe settings button. Flat preset list with dashed dividers: HIDIT on top with a small ladder glyph of shrinking bars, then Norwegian 4x4, 30/30, Tabata, Custom. HIDIT and Custom open an editor. Below the list, a black card repeats the selected session's total time as a big numeral with a diagonal arrow. Start button (charcoal pill) at the bottom.
2. **HIDIT builder:** taupe back button. A Steps stepper adds or removes the last step (2 to 10). Each step has its own work stepper (5 second increments, 0:10 to 10:00) and shows its recovery, which is read-only and always work x 2/3. A preview card shows paired work and recover bars per step, separated by dashed guides, with step numbers and the total time as a big numeral.
3. **Get ready:** 10-second countdown as a very large numeral at the bottom left with a diagonal arrow, "First: run hard 3:00", Skip and Cancel.
4. **Run, work:** red phase. Up-right arrow, percent of the phase, a thin progress line with an end dot filling forward, "Run hard", giant timer, "Step 2 of 5", "Next: recover 1:40", full-width Pause.
5. **Run, recover:** same layout in graphite. Down-right arrow, the line draining backward, "Next: run hard 2:00". Pause becomes Resume where paused.
6. **Paused:** dimmed timer with Resume and an outlined End run.
7. **Finish:** total time as a big numeral, a two-column grid of big-numeral stats (steps completed, longest work, work time, recover time), Done.
8. **First launch:** one-line health note ("Check with a doctor before high-intensity training") and a Got it button.
9. **Settings sheet:** frosted sheet with sound (on, off, voice only), haptics, volume boost, countdown ticks, countdown length, and test-cue buttons for run, recover and finish.

## HIDIT logic

HIDIT is a fixed ladder of work intervals that gets shorter each step. Recovery is always work x 2/3, so the 3:2 ratio cannot be broken. The default five-step ladder, which is also the HIDIT format to follow:

| Step | Run (high intensity) | Recover (jog or walk) |
| --- | --- | --- |
| 1 | 3:00 | 2:00 |
| 2 | 2:00 | 1:20 |
| 3 | 1:00 | 0:40 |
| 4 | 0:45 | 0:30 |
| 5 (the loop) | 0:30 | 0:20 |

The intervals total 12:05 (7:15 of work, 4:50 of recovery), plus warm-up and cooldown outside the app. The work times do not follow one repeated step-down, so the builder edits each step's work directly. Fixed presets remain available. The full schedule is precomputed at start.

## Cue system: run versus recover

Every phase change is identifiable through at least two of three channels: sound, touch, sight.

**Sound**

- Run start: two short, bright rising beeps (high pitch). Recover start: one long, soft falling tone (low pitch).
- Last 3 seconds: three short rising ticks before recover, three soft flat ticks before run.
- Finish: three-note ascending chime.
- Optional voice: "Run" and "Recover", plus the step number on step changes.

**Haptics**

- Run start: two sharp taps (double pulse). Recover start: one long, gentle buzz.
- Last 3 seconds: three light taps into recover, three soft taps into run.
- Finish: strong triple pulse.

**Visual**

- Run: soft red wash, red timer, "Run hard", up-right arrow, progress fills forward, brief brightness pulse (150 ms) on change.
- Recover: soft graphite wash, graphite timer, "Recover", down-right arrow, progress drains backward, slow fade (300 ms) on change.
- Last 3 seconds: timer pulses each second.
- Color is never the only signal: the phase label, the arrow direction and the bar direction differ too.

Phases of 20 seconds or less skip the 3-2-1 ticks and use only the phase-start cue.

## Countdown

- **Pre-run:** after Start, a 10-second "Get ready" countdown (5, 10, 15 seconds, or off). Soft tick per second from 10 to 4, three rising beeps at 3, 2, 1, run cue at zero. Light haptic tap at 3, 2, 1 and a double pulse at zero. The number pulses each second and the screen cross-fades to the first phase color at zero.
- **Warm-up end:** the last 10 seconds show "Run starts in" with a countdown.
- **In-run:** last 3 seconds before every phase change, as described above.
- **Pause:** pausing during the pre-run countdown cancels it. Pausing mid-run freezes the clock, and Resume gives a fresh 3-second "Ready" countdown.

## Interaction and accessibility

- Run controls are at least 72 pt tall and thumb-reachable. No menus mid-run.
- Screen stays awake and the timer keeps running on the lock screen.
- Contrast at least 4.5:1, timer at least 4.5:1. Support Dynamic Type. Tap targets at least 48 pt. Respect reduced motion.
- Copy: sentence case, verb-first buttons (Start, Pause, Resume, End run). Phase labels "Run hard" and "Recover". No exclamation marks or motivational filler. Small labels and headings are uppercase by design.

## Constraints

Portrait only, 390 x 844 base frame. No accounts, GPS, ads, or social features. Fully offline, under 10 MB, launches in under 1 second, timer drift under 100 ms over 30 minutes.

## Deliverables

All screens in light mode, the HIDIT builder in default and edited states, run screens in both phases plus paused, the component set (preset row, stepper, ladder preview, phase timer, progress bar, primary action button), and color and type tokens.

## Design references

- [Axis Gray design system](https://claude.ai/artifact/Mn12U5Z12VxoYJQwezPdj7) (copy in `docs/design-system/`): color, type, spacing and radius tokens. Build from these, not from the values in this brief if they differ.
- [Working prototype](https://claude.ai/artifact/PsGzH4SQSExNpubaamv9gU) (copy in `prototype/hidit.html`): reference for behavior, cues, layouts and copy.
- [Wireframes](https://claude.ai/artifact/HdVoBP2SBztuMP4W3poRKi) (copy in `docs/wireframes/`): screen inventory and component set. Its run and home layouts predate the big-numeral update, so follow the prototype where they differ.

## Changes from the first brief

- Light mode only. Dark mode is out of scope.
- Phase colors are red (work) and graphite (recover), replacing green and blue. The clay accent is dropped; the main action is a charcoal pill.
- Michroma and Hanken Grotesk replace SF Pro and Roboto Flex. Numbers are shown as big numerals throughout.
- Home gains a black summary card. Run screens add a direction arrow and a percent.
