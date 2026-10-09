# Papá o la papa: notes for Claude

One-screen phone prototype. The screen says **"Translate / Dad"**; the person
says it in Spanish and whatever they actually pronounced is painted onto the
page in watercolor, with a caption:

| Heard          | Paints     | Caption (meaning / Spanish)             | Colour   |
|----------------|------------|------------------------------------------|----------|
| el papa        | the Pope   | the Pope / El papa                       | #c14d1f  |
| la papa / papa | a potato   | the potato / La papa                     | #c14d1f  |
| papá           | Dad        | the dad / El papá                        | #2f88a6  |

Spanish spelling: "papa" (Pope, potato) is lowercase, as Spanish writes titles;
"papá" with the accent is dad. Figma's "La papá" for the potato was a typo.

The design source is Figma file `UAgpMOHbjQMcWBCS4qVhg9` ("Side-project"):
main screen node `109:254` (potato state), Pope `92:1380`, Dad `92:1399`.

The point is the near-miss: people trying to say "papá" often say "el papa" or
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

## Layout (matches the Figma frames)

- The phone is a 402 × 874 design. Every size is `calc(N * var(--u))` with
  `--u: calc(100cqw / 402)` on `.stage`, scaled to fit. Page colour `#fafafa`
  (by request; Figma used `#f5f2ee`), under the paper texture; square corners (radius 0, by request).
- Top: the progress strip (six blob shapes at 20% opacity, centred). The user
  asked for it 40% smaller than in Figma, then 10% wider gaps: 178 × 7u at y ≈ 72.
  No close button: the main Figma frame has none.
- Title in SF Pro (system font stack `--sf`): "Translate" Light 20px at 40%
  black, y 130; "Dad" Regular 28px `#302e2a`, y 158.
  Before the first word (and after "next") the title sits 60u above the vertical
  centre of the page (`.stage[data-intro]`); it glides up to y 130 as soon as
  the mic is pressed (`beginTake()`), and goes back if the take ends with no picture.
- Listening wash: while listening, six translucent watercolor layers bloom in
  one after another where the picture will appear (`svg.smudge`, 250 × 300u
  centred on (199, 378), about the Dad portrait's size). Each is a wobbly blob
  (`blobPath`) with a ragged, pigment-rimmed edge (`#wash0-2` filters),
  multiplied over the others; they drift slowly and swell a little with the
  voice. When speaking ends they wash away over the painting time while the
  picture paints in (`washOn()` / `washOff(ms)`). Any picture from the last take fades
  when the mic is pressed. Adjust → Listening wash: presets Light blue
  (default, hsl 205 75% 68%), Aqua, Perplexity (#20808D-ish), Indigo, plus hue,
  saturation, lightness and strength sliders (moving one previews the wash).
- Pictures: watercolor cut-outs drawn by a WebGL canvas covering y 90–590 at
  full width (normal blending, so the Bleed layer stays behind it), each in its box (`PICTURES` in the script).
- Caption: meaning in SF Pro Light 16px at 80%, y 541; Spanish in Regular 28px,
  y 565; colour per word (table above). A miss shows "No te entendí" and the
  transcript in grey. While speaking, the Spanish is typed out live in black, syllable by syllable
  (`showLive()`; real transcripts from the mic, or `syllables()` timed to the
  demo voice). When speaking ends the result takes over: wrong answers turn red
  and shake in place, Dad's glare plays (`.from-live`). The Dad caption's lines fade in rising 10u with a
  2px blur that clears (450ms, strong ease-out), the Spanish word 70ms after
  the meaning (`.caption.enter`, `rise-in`); live transcripts don't animate. When Dad is said (correct), the caption turns black and a
  glare of the blue sweeps across it once, straight away (`.caption.shine`).
  For the Pope and the potato (wrong answers) there is no glare: the caption
  starts black and quickly changes to the red, which stays (`.caption.redden`).
- Wrong answer (the Pope or the potato): **Edges** only. A soft colour creeps
  in evenly along every side (eased in many small steps) while both caption
  lines appear (no rise) and shake straight away "no"; the voice button turns 70% opaque so the colour shows
  through. Adjust → Wrong answer: Edge hue (0–360°, default 16° = soft red
  hsl(16 70% 62%)), Edge strength (0–250%), and a Show wrong answer button. Edge time
  (0.2–6s, default 1s) sets how long the edges take to creep in.
  The stage carries `data-won`; `.won-play` replays the shake. It clears when
  listening starts again or Dad is said. (Rise, Shake, Bleed, Ripples,
  Scribble and Blush were tried and dropped; they're in git history.)
- Voice blob centred at (201, 674.5), 20% smaller than the Figma pebble
  (about 85 × 70); the tap-word chips sit below it.
- Adjust panel: a column beside the phone at ≥980px wide, otherwise a bottom
  sheet behind an "Adjust" button. It holds Try a word, Paper (tooth size, tooth
  depth, warmth: 0 = `#fafafa` default, 1 = `#f5f2ee`), Painting time, Wrong answer, Listening wash, and Voice visual.

## Pictures

`assets/{potato,pope,dad}-cutout.png` are split from the user's
`assets/pictures-source.webp` (three transparent cut-outs side by side), each
with a 24px transparent margin and a blur that ramps in over its lower 45%
(colour and alpha blurred premultiplied, so no dark fringes). `PICTURES` boxes
are each picture's visible bounds in the Figma frames; `layer()` ignores the
24px margin when sizing. `assets/{pope,potato,dad}.jpg` and `*-mask.png` are
the older full watercolors, no longer used by the page.

## Visual decisions (the user asked for these; keep them)

- **Paper**: heavy cold-press watercolor stock, a generated SVG (`feTurbulence`
  height map + `feDiffuseLighting`) rendered as **one full-screen sheet, not
  tiles**. It lies **over everything on the page** (pictures, type, voice blob)
  as two neutral layers, `.grain-shade` (multiply) and `.grain-light` (screen),
  above a plain page colour. Sliders: tooth size (log 0.25×–4×), tooth depth
  (0 = smooth), warmth.
- **Painting**: a new picture fades in from a blurred copy and comes into focus.
  When the word changes, the old picture dissolves while the new one fades in.
  Painting time is adjustable (default 1s).
- **Voice blob** (kept from before the Figma pass):
  - Single **pebble** (outline tilted 12° clockwise; the icons stay upright), near-white grey `#efeeec`, soft watercolor edge.
  - Listening: satellite blobs slide out and merge via a gooey SVG filter
    (`#blob-goo`) into a wide shape that swells with volume. It stays grey and
    its edge goes paler and blurs out into the paper (CSS blur on `.blob`,
    `--listen-blur`, default 3.5u; Adjust → Voice visual → Edge blur while listening).
  - Inside while listening: five large, blurred, light pastel drops fill the
    shape (clipped to it). Looks: **Swirl** (default; clockwise, about one lap
    per 30s), Marble, Ripples, Ellipses. Motion is slow.
  - Processing (while the picture paints): no loading indicator; the mic stays.
  - The mic uses the **pencil** filter in `--mic-ink #7f7d7a`. The mic
    capsule is filled with that ink at 48% on white; the icon is about 19 × 25u.
  - After Dad (correct) the mic swaps straight from listening to a pencil "next" arrow that nudges right once (`.next`,
    `data-next` on the button). Tapping it fades the picture and caption out,
    moves the progress dot on, and brings the mic back (`goNext()`).

## Tried and rejected (don't bring back without asking)

- Spreading wash fronts with pale/whitened layers ("white glare"); blooming
  patches; a pen-stroke/hatching reveal of the subject.
- Fading the old picture out before painting the next.
- A blue listening state; a rounded-square or speckled/grainy pad; Bean and Cloud
  blob shapes; a "watercolor smudges" look for the voice blob (smudges are
  used for the listening wash in the picture spot instead).
- Mottled/fibrous paper grain; a tiled paper texture.
- Earlier, pre-Figma look (now replaced by the Figma design): Gaegu
  handwriting, the hand-drawn close X, "Translate: Dad" on one line, the
  rectangular blurred frame with edge-fade/edge-blur/softness sliders, and the
  background-vs-subject colour-morph painter.

## Code map (index.html script)

- Settings: `ids` list plus `localStorage` key `papa-settings-vN`. Bump N when
  defaults change; older saved values are migrated where it matters.
- Paper: `applyPaper()`.
- Painter: `PICTURES`, `layer(img, box, blur)`, `layersFor(key)`,
  `bind("A"|"B", layers)`, `paint(key)`, `tween(ms, step, alive)`.
- Caption: `CAPTION`, `showCaption()`, `showHeard()`.
- Voice: `setState("idle"|"listening"|"processing")`, `renderBlob()` /
  `renderMix()`, `animateWaves()` (volume levels, real mic via `AnalyserNode`
  or a synthetic envelope), `listen()`, `simulate()`.
