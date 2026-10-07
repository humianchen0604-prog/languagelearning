# Papá o la Papa: notes for Claude

One-screen phone prototype. The screen says **"Translate: Dad"**; the person
says it in Spanish and whatever they actually pronounced is painted into the
frame in watercolor:

| Heard          | Paints     | Caption        |
|----------------|------------|----------------|
| el Papa        | the Pope   | "the Pope"     |
| la papa / papa | a potato   | "a potato"     |
| papá           | Dad        | "Dad. ¡Eso!"   |

The point is the near-miss: people trying to say "papá" often say "el Papa" or
"la papa" first. Classification is in `classify()`, which checks every speech
alternative.

Everything lives in `index.html` (no build step). Assets are in `assets/`.

## Run and check

```sh
cd papa && python3 -m http.server 8000   # mic needs http(s), not file://
```

- Real speech: Chrome or Safari via `localhost`, using `webkitSpeechRecognition` with `es-MX`.
- No speech API, or the mic is refused: tapping the mic shows three tap-words.
  The Adjust panel's "Try a word" buttons run the whole sequence without speaking.
- The published claude.ai artifact can't use the microphone, so it always uses
  the tap fallback. Artifact: https://claude.ai/artifact/MrvbqSWJfhkj1HsnJr35ku
  (republish `index.html` with `assets/*` as supporting files).
- Visual checks were done with Playwright screenshots of the `.frame` and
  `#voice` elements. WebGL needs `--use-gl=swiftshader` in headless Chromium.

## Layout

- The phone is a 402 × 874 design (Figma units). Every size is
  `calc(N * var(--u))` with `--u: calc(100cqw / 402)` on `.stage`, scaled to fit.
- Top: a hand-drawn close X; a progress bar of **6 blob shapes** traced from the
  user's watercolor strip (neutral grey `#dadada`, first/current `#8c8c8c`, 12u
  tall); the title "Translate: Dad" in **Gaegu** bold, 26u.
- Frame (270 × 360u, 3:4): a WebGL canvas with `mix-blend-mode: multiply`, so the
  paper shows through the paint. Before the first word: a blurred grey placeholder.
- Voice blob, centered at y≈645, then the "heard" caption, then tap-words.
- Adjust panel: a column beside the phone at ≥980px wide, otherwise a bottom
  sheet behind an "Adjust" button.

## Visual decisions (the user asked for these; keep them)

- **Paper**: heavy cold-press watercolor stock, cream-white leaning white. It's a
  generated SVG (`feTurbulence` height map + `feDiffuseLighting`) rendered as
  **one full-screen sheet, not tiles** (tiles showed seams). Sliders: tooth size
  (log scale 0.25×–4×), tooth depth (0 = perfectly smooth, eased so the low end is
  fine-grained), warmth.
- **Font**: Gaegu only (Google Fonts). Ugly Duck was wanted but no font file was
  ever provided; the font picker was removed once Gaegu was chosen.
- **Images**: `pope.jpg`, `potato.jpg`, `dad.jpg` (the user's watercolor
  portraits, 816 × 1088). `*-mask.png` are soft hand-traced subject outlines.
  The frame edge fades and blurs irregularly (sliders: edge fade, edge blur,
  overall softness, painting time; default 2.2s).
- **Painting**:
  - First picture: the background fades in quickly, soft and slightly off-hue,
    then sharpens and settles into its own colours. The subject (inside its
    mask) fades in a beat later and comes into focus. No white areas and no glare.
  - Switching pictures: the background **never fades out**. Each pixel's
    hue/lightness/chroma morphs (YIQ, shortest way round the hue wheel) from the
    old picture to the new. The old subject dissolves into it, then the new
    subject fades in. Both pictures are bound at once (A = old, B = new) and each
    mask rides in the alpha channel of its wash texture, to stay within 8 texture units.
- **Voice blob**:
  - Single **pebble** shape, near-white grey `#efeeec` with a soft watercolor edge
    (pale tideline fading inward plus a slight bleed outward). No hard rim.
  - While listening: four hidden satellite blobs slide out and merge through a
    gooey SVG filter (`#blob-goo`) into a wide shape that swells with volume.
    It stays grey (no blue); its edge goes paler while listening.
  - Inside while listening: five large, heavily blurred pastel drops (`.dab`,
    lighter blue, sage, sand, rose, lilac) that fill the shape completely (no grey
    showing), clipped to the blob. Looks: **Swirl** (default; drops travel
    clockwise round the shape, about one lap per 30s), Marble, Ripples, Ellipses.
    Motion is deliberately slow.
  - Processing: the blob returns to grey with three small pulsing dots.
  - Mic and dots are drawn with the **pencil** filter (`#pencil`: slight wobble
    plus paper grain) in `--mic-ink #7f7d7a`. The mic capsule is filled with that
    ink at 48% on white. The mic icon is about 17 × 23u.

## Tried and rejected (don't bring back without asking)

- Spreading wash fronts with pale/whitened layers ("white glare"); blooming
  patches; a pen-stroke/hatching reveal of the subject.
- Fading the old picture out before painting the next.
- A blue listening state; a rounded-square or speckled/grainy pad; Bean and Cloud
  blob shapes; a "watercolor smudges" look.
- Mottled/fibrous paper grain; a tiled paper texture.

## Code map (index.html script)

- Settings: `ids` list plus `localStorage` key `papa-settings-vN`. Bump N when
  defaults change; older saved values are migrated where it matters.
- Paper: `applyPaper()`.
- Painter: `FRAG` shader, `bind("A"|"B", layers)`, `layersFor(key)`,
  `paint(key)` (first-picture and switching timelines), `tween(ms, step, alive)`.
- Voice: `setState("idle"|"listening"|"processing")`, `renderBlob()` /
  `renderMix()` (blob shape plus colour drops), `animateWaves()` (volume levels,
  real mic via `AnalyserNode` or a synthetic envelope), `listen()`, `simulate()`.
