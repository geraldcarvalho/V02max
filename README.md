# HIDIT

A lightweight iOS interval timer for VO2 max training, built in SwiftUI. It runs HIDIT (High-Intensity Decreasing Interval Training: work and recovery shrink each step at a fixed 3:2 ratio) plus Norwegian 4x4, 30/30, Tabata and custom workouts. v1 is iOS only.

## Sources

| What | Repo copy | Online source |
| --- | --- | --- |
| Product spec | [docs/PRD.md](docs/PRD.md) | [Claude Docs](https://claude.ai/artifact/8ZAdn1RV6QvnJzDbWzmRWA) |
| Design system (Axis Gray) | [docs/design-system/](docs/design-system/) (`README.md`, `tokens.json`) | [Design System](https://claude.ai/artifact/Mn12U5Z12VxoYJQwezPdj7) |
| Working prototype | [prototype/hidit.html](prototype/hidit.html) | [Artifact](https://claude.ai/artifact/PsGzH4SQSExNpubaamv9gU) |
| Wireframes | [docs/wireframes/](docs/wireframes/) (`canvas.json` + one `.dc.html` per screen) | [Design canvas](https://claude.ai/artifact/HdVoBP2SBztuMP4W3poRKi) |

When sources disagree:

1. Design tokens come from `docs/design-system/tokens.json`.
2. Behavior, cues, layouts and copy follow the prototype.
3. The wireframes give the screen inventory and component set. Their home and run layouts are older than the prototype's.

The prototype opens in any browser (it loads its two fonts from Google Fonts). The wireframe `.dc.html` files are Claude Design markup; read them for sizes, colors and copy. They do not render standalone.

## Status

Setup only. The app has not been built yet.

## Known platform limits

- iOS does not play haptics while the app is in the background or the screen is locked. Background cues rely on audio (and a notification as backup); haptics fire whenever the app is in the foreground.
