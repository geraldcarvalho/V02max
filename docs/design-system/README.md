# Axis Gray

A quiet, light-only system for utility apps used in motion, built only from the colors in its reference image: grays, white, taupe, black, one red and one orange. Warm gray ground, thin type, monospace labels, concentric hairline circles and one soft red-orange gradient. Built for the HIDIT interval timer, reusable for any single-purpose mobile tool.

## Content fundamentals

- Sentence case for headings and buttons. Labels are uppercase and small.
- Verb-first buttons: Start, Pause, Resume, End run, Done.
- Short and factual. No exclamation marks or motivational filler.
- Numbers are data: `16:40`, `Step 2 of 5`, `Next: recover 1:40`.

## Visual foundations

- **Ground:** flat `ground`, cards on `surface`, `hairline` borders. No shadows.
- **Type:** Michroma, a wide squared display face, sets every number and every heading. Numbers are the hero: the timer runs 84 to 112 px, stats and stepper values 22 to 26 px. Hanken Grotesk carries body text in light weight and uppercase 11 px labels in `muted`. Uppercase Michroma marks headings and phase names.
- **Big numbers:** use `numeral-xl` or `numeral-lg` for the one number that matters on a screen, placed bottom left with a heavy square-cap diagonal arrow bottom right. A black `ink` card repeats the total.
- **Action:** one main action per screen, a 72 px `ink` pill with white text (`radius-pill`). Icon buttons are `taupe` squircles (`radius-button`) with a white glyph.
- **Phase color:** `work` red and `recover` graphite tint the run screen background at 12 percent and color the timer. Color is never the only signal: the phase label and the progress direction differ too.
- **Data marks:** thin 1 px lines, dashed vertical guides in `hairline`, an end dot on the current value.
- **Decoration:** three or four concentric hairline circles and a `signal` to `ember` blurred gradient blob at the bottom of calm screens (home, get ready, finish, first launch). Never behind the run screen.
- **Layout:** 20 px side margins, single column, left aligned, the run timer centered.

## Iconography

Thin outline icons, 1.5 px stroke, drawn sparingly. Icon glyph is white on taupe or `muted` on ground.

## Usage rules

- Text on `ground` uses `ink` or `muted` only. Never `signal` for text.
- `signal` appears only in the gradient blob and focus dot, never as a button fill.
- Tap targets are at least 48 px, run controls 72 px.
