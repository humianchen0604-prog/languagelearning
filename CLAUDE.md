# Papá o la papa: notes for Claude

(This repo, `languagelearning`, was split out of the `portfolio` repo's
`papa/` folder with its history; the files that were in `papa/` are now at the root.)

One-screen phone prototype. The screen says **"Translate / Dad"**; the person
says it in Spanish and whatever they actually pronounced is painted onto the
page in watercolor, with a caption:

| Heard          | Paints     | Caption (meaning / Spanish)             | Colour   |
|----------------|------------|------------------------------------------|----------|
| el papa        | the Pope   | the Pope / El papa                       | edge hue |
| la papa / papa | a potato   | the potato / La papa                     | edge hue |
| papá           | Dad        | the dad / El papá                        | #2f88a6  |

Wrong-answer captions use the same hue as the wrong-answer edges
(`--say-papa: hsl(var(--edge-h) 62% 46%)` on `.stage`, strawberry red by
default; it was the tomato `#c14d1f` until the user asked them to match).

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
python3 -m http.server 8000   # mic needs http(s), not file://
```
**The user views the prototype on localhost on their Mac, not the claude.ai
artifact (by request): push changes to `main` here and tell them to
double-click `start.command` (it runs `git pull` first) or reload the page.
Also republish the claude.ai artifact when they ask (copy index.html and
assets/ to the scratchpad first; the Artifact tool only takes files there).**

`start.command` does the same (first free port from 8000) and opens Chrome; the
user double-clicks it on their Mac.

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
  Around the phone the preview background is white (`--surround: #fff`) and the
  phone has no drop shadow (both by request).
- Top: the progress strip (six blob shapes at 20% opacity, centred). The user
  asked for it 40% smaller than in Figma, then 10% wider gaps: 178 × 7u at y ≈ 84
  (moved 12u down, by request).
  No close button: the main Figma frame has none.
- Title in SF Pro (system font stack `--sf`): "Translate" Light 20px at 40%
  black, y 142; "Dad" Regular 28px `#302e2a`, y 170 (both moved 12u down, by request).
  Before the first word (and after "next") the title sits 60u above the vertical
  centre of the page (`.stage[data-intro]`); it glides up to y 142 as soon as
  the mic is pressed (`beginTake()`), and goes back if the take ends with no picture.
- Opening (on load, once): the progress dots pop in left to right, "Translate"
  then "Dad" rise 14u with a blur that clears, then the voice blob blooms in
  (scale 0.8, blur) and the mic appears; about 1.2s in all (`open-*` keyframes,
  backwards fill only so the elements' own styles take over afterwards).
- First-picture wash: only when the page has no picture yet (first word,
  after "next", after a miss), a soft grey watercolor paints itself in where
  the picture will appear, spreading from the centre outward (it went from the
  top left to the bottom right until the user asked for centre-out), as soon as
  the mic is pressed. It is the user's watercolor (`assets/loading-wash-source.png`,
  turned into a pigment mask `assets/loading-wash.png`, white = paint) filling
  a grey rect (`#washFill`, hsl 30 5% L), revealed by a radial gradient (centre
  out) with a brushy, displaced front (`#revealMask`, `revA`/`revB` stop offsets driven
  in `renderWash()`). Box 300 × 284u centred on (199, 370).
  When speaking ends it first finishes painting, then loosens, blurs and fades
  out; the picture starts painting in when the fade is 85% through (Adjust →
  Picture starts at), so the two barely overlap. History: waiting for a full
  fade was too long a pause, starting at half overlapped too much; `finish()`
  awaits it.
  Adjust → First-picture wash: paint-in time, grey lightness, strength,
  fade-out time, blur (defaults are the user's tuned values, below).
  **Reveal style** (Adjust → First-picture wash; remembered in
  `papa-reveal-v1`, included in Save settings): how the finished grey wash
  turns into the first picture. "Fade" is the wash fading out with the picture
  starting near the end of the fade (85%). The ten others (the user asked for ten ideas and
  wanted to try all) hand the wash over to the WebGL painter at the moment it
  finishes painting: `revealPaint(key, mode)` draws the same grey (pigment
  texture `tWash`, colour, box `uBox`) in the shader, hides the SVG wash in the
  same frame (`washHandoff()`; pixel-checked: within 1–2 levels), then plays
  `uMode` 1–10 over Reveal time (default 1.8s): 1 Underpainting (colour soaks
  into the grey from the inside; its front is a smooth sine warp, as noise
  showed grid lines), 2 Bloom (wet-into-wet from the centre with a
  grey rim pushed out), 3 Brush pass (second diagonal stroke wipes grey,
  reveals picture), 4 Glazing (four even glazes deepen the colour, lights
  first), 5 Settling (pale larger blot settles, sharpens, gains colour),
  6 Drying edges (wet wavering edges firm up, tideline flash), 7 Granulation
  (speckles into the paper's tooth, darkest first), 8 Blotting (tissue patches
  lift the grey), 9 Wicking (colour creeps in from the outline, `tGlow` = a
  40px-blurred copy as depth), 10 Brush strokes (five soft strokes, the last
  over the middle). Every mode ends exactly on the sharp picture. The shader's `fbm` uses
  quintic value noise with rotated octaves so no lattice/grid shows. Picking a
  style, or the Try buttons, empties the page and plays a take (`tryReveal()`).
  Between pictures there is NO wash: the old picture stays while listening and
  dissolves into the new one (the original effect; the user asked to keep it).
  Tried and dropped: a blue wash for every take; six layered grey blob washes.
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
  glare sweeps across it once in the light blue of the "next" button, a little
  darker (`--shine: #9fcfe2`, middle `--shine-hi: #c2e2ee`; it was the deep
  `#2f88a6` until the user asked to match the button), starting 0.5s after the word appears (`.caption.shine`).
  For the Pope and the potato (wrong answers) there is no glare: the caption
  starts black and quickly changes to the red, which stays (`.caption.redden`).
- Wrong answer (the Pope or the potato): **Edges** only. It waits for the picture: the
  red edges and the red, shaking caption start only when the picture starts
  painting in (after the first-picture wash's half fade), never over the grey
  wash (by request); until then the live transcript stays in black. A soft colour creeps
  in evenly along every side (eased in many small steps) while both caption
  English meaning fades in as soon as speaking ends, in black (200ms, class
  `pre-meaning`), even while the first-picture wash is still going; when the
  picture starts, both lines turn red and shake "no" (`pre-shown`). When there
  is no wash to wait for: the word turns red, the meaning fades in at 40ms
  (200ms) and both shake at 300ms; the voice button turns 70% opaque so the colour shows
  through. Adjust → Wrong answer: Edge hue (0–360°, default 354° = soft strawberry
  red hsl(354 70% 62%); it was 16°, a tomato red, until the user asked for strawberry), Edge strength (0–250%), and a Show wrong answer button.
  The colour fades out SOFTLY and gradually on all four sides, right into the
  page colour, with no defined edge line and no denser band inside (final
  call from the user, with a side-by-side screenshot: "like this photo left
  side how it fades out on all four edges softly"). It still reads as
  watercolor: sheer, uneven pigment, deepening toward the screen's edge,
  gently wavy. CSS `filter: url(#edge-bloom)` on `.w-edges` uses the gradient
  as a distance map (smoothed, warped), and `edgeTable()` turns distance into
  the wash (`#ebTable`). Edge rim slider (0–250%, default 0%) can add a soft,
  slightly denser band. Tried and rejected: zig-zag fibres along the edge; a
  defined wavy edge with a dense rim (the user went back and forth once, then
  settled on the soft fade). Edge time
  (0.2–6s, default 1s) sets how long the edges take to creep in.
  The stage carries `data-won`; `.won-play` replays the shake. It clears when
  listening starts again or Dad is said. (Rise, Shake, Bleed, Ripples,
  Scribble and Blush were tried and dropped; they're in git history.)
- Voice blob centred at (201, 674.5), 20% smaller than the Figma pebble
  (about 85 × 70); the tap-word chips sit below it.
- Adjust panel: a column beside the phone at ≥980px wide, otherwise a bottom
  sheet behind an "Adjust" button. It holds Restart prototype (reloads the page;
  settings are kept; also an always-visible "↺ Restart prototype" button at
  the window's bottom left, `.restart-fab`), Try a word, Paper (tooth size, tooth
  depth, warmth: 0 = `#fafafa` default, 1 = `#f5f2ee`), Painting time, Wrong answer, Mic smudges, First-picture wash, and Voice visual.

## Saving tuned settings

Current defaults are the user's own tuned file (2026-10-09), settings key
`papa-settings-v19`: tooth size −1.49, tooth depth 0.27, warmth 0.1, painting
time 1s, edge hue 354, edge strength 1.36, edge time 1s, edge rim 0; mic
smudges hue 30 / sat 0.05 / light 0.88 / density 0.2 / softness 1.5; listening
blur 3.5, listening grey 3.5%; first-picture wash lightness 0.3, strength 0.1,
fade 0.5s, blur 0, paint-in 1.9s; voice look Grey.

Adjust → Save → **Save settings** downloads `papa-settings.json` (every
slider's value plus the voice look and reveal style), copies it, and shows it in the panel.
When the user sends one, make those values the defaults: set each input's
`value` attribute (and the look's default), then bump the settings key so the
new defaults show.

## Pictures

`assets/{potato,pope,dad}-cutout.png` are split from the user's
`assets/pictures-source.webp` (three transparent cut-outs side by side), each
with a 24px transparent margin and no blur (a bottom blur was tried and removed
by request). `PICTURES` boxes
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
  - While listening, Looks: **Pebble** (default; `grey` in code and the saved
    look key `papa-look-v4`): the button keeps its resting pebble shape and
    size, contained in its own edge (no listening blur), no icon, and turns
    the light blue of the correct answer (`--blob-next: #d5edf6`, rim
    `#8fc3d8`) while it wiggles (wobblier outline) and twirls back and forth a
    little (±~15°). A correct answer keeps the blue behind the "next" arrow; a
    wrong answer or a miss eases back to grey and the mic returns. (Before
    that it was a darker grey while listening, 8% then 3.5%.)
  - **Smudges** (was the default before Grey): the button keeps its
    resting pebble shape and size (no satellites, no widening; the user
    dropped the wide "snake" shape for this look). Eight pebble-shaped
    watercolor smudges (`PEBBLE.radii`, jittered), stacked in its centre
    largest first, bloom in one after another on top (growing and turning a
    little into place, `.blob-smudges`, `#mwash0-2` filters), drift slightly
    and swell with the voice. Light blue in the hue of Dad's glare by default
    ("Dad blue", hsl 196 60% 78%), with soft, blurred-out edges (Edge
    softness, default 3.5). Adjust → Mic smudges: Dad blue (default), Light
    gray, Light blue, Aqua, Perplexity, Indigo, or hue/saturation/lightness,
    Colour density (0–300%, default 100%) and Edge softness. Moving one of
    these sliders previews the smudges on the button for ~2s (`previewMic()`).
    While listening with Smudges, the grey button itself fades out (no grey
    under the smudges, by request): only the blue layers of different sizes,
    blurred, adding up (Edge softness default 5, plus half the listening blur). Settings key `papa-settings-v18` (older
    wash and smudge values are dropped on migration so new defaults show). The other looks
    fill the shape with five blurred pastel drops (clipped to it): Swirl
    (clockwise, about one lap per 30s), Marble, Ripples; or Ellipses. Motion is
    slow. 
  - Back from listening (e.g. after a wrong answer) it morphs, not switches:
    the wiggle/twirl settles slowly (`spread` eases back at 0.035/frame, about
    a second), the grey eases back over 900ms, and the mic just fades back
    in 300ms later (500ms; no zoom, by request).
  - Processing (while the picture paints): no loading indicator; the mic stays.
  - The mic uses the **pencil** filter in `--mic-ink #7f7d7a`. The mic
    capsule is filled with that ink at 48% on white; the icon is about 19 × 25u.
  - After Dad (correct) the button's grey fades to a light blue from Dad's
    glare (`--blob-next: #d5edf6`, 700ms) as the arrow appears, and its rim turns
    blue (`#blobRim` flood `#8fc3d8`) instead of grey.
  - After Dad (correct) the mic swaps straight from listening to a pencil "next" arrow that nudges right once (`.next`,
    `data-next` on the button). Tapping it fades the picture and caption out,
    moves the progress dot on, and brings the mic back (`goNext()`).

## Tried and rejected (don't bring back without asking)

- Spreading wash fronts with pale/whitened layers ("white glare"); blooming
  patches; a pen-stroke/hatching reveal of the subject.
- Fading the old picture out before painting the next.
- A blue listening state; a rounded-square or speckled/grainy pad; Bean and Cloud
  blob shapes. (An early "watercolor smudges" voice look was rejected, but the
  user later asked for the current Smudges look.)
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
