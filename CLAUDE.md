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
| papá           | Dad        | the dad / El papá                        | black    |

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
- First-picture wash: for every take (by request; it used to be only when
  the page had no picture yet). When a picture is showing, e.g. a wrong
  answer, pressing the mic fades it out (`clearPicture()`) as the wash appears,
  so each new picture is generated the same way. That change is gentler (by
  request): the picture fades out over 850ms (not 600) and the wash starts
  only once it is gone (850ms, no overlap, by request) with a plain, slower opacity fade (2× the fade-in time, at least
  0.9s) and no scale (`washOn(true)`, `washSoft`). When the title is gliding up
  (first take, after "next" or a miss), the wash waits until the glide is 90%
  done (~495ms, `TITLE_90`) before fading in; everything after follows from
  then (`washOnAt`). A soft grey watercolor appears where the
  picture will appear as soon as the mic is pressed, quickly fading in while it
  scales from 95% to 100% (Fade-in time, default 0.45s). History: it first
  painted in from the top left to the bottom right, then from the centre
  outward; the user then asked for this faster fade-and-scale. It is the user's watercolor (`assets/loading-wash-source.png`,
  turned into a pigment mask `assets/loading-wash.png`, white = paint) filling
  a grey rect (`#washFill`, hsl 30 5% L), (`#revealMask`, the old paint front, is
  now held fully open in `renderWash()`). Box 264 × 250u centred on (199, 370) (12% smaller than the
  first 300 × 284, by request; `uBox` in `revealPaint()` must match `.smudge`).
  When speaking ends it first finishes painting, then loosens, blurs and fades
  out completely, and only then does the picture paint in (Adjust → Picture
  starts at, default 100%: no overlap; the user insisted, "make sure the gray
  picture wash fade out first, and then show the image"). History: half and
  85% overlaps were tried first; `finish()` awaits it.
  The grey's exit starts as soon as the word is ~95% said (`exitWash()`: with
  the real mic, when its volume shows the speaker has spoken and then been
  quiet for 220ms (`watchSpeechEnd()`, by request: follow the speaker's
  input), or the recogniser's speech end, whichever comes first; or 180ms after the demo voice's last syllable;
  the demo result follows 170ms later; the picture's entry was
  moved 15%, then another 20%, earlier by request), so the picture follows the word closely.
  Adjust → First-picture wash: fade-in time, grey lightness, strength,
  fade-out time, blur (defaults are the user's tuned values, below).
  **Reveal style** (Adjust → First-picture wash; remembered in
  `papa-reveal-v3`, default Underpainting (the user's tuned file), included in Save settings; only Fade keeps
  the grey and the picture strictly apart, the other ten blend them by design): how the finished grey wash
  turns into the first picture. "Fade" is the wash fading out completely, then
  the picture. The ten others (the user asked for ten ideas and
  wanted to try all) hand the wash over to the WebGL painter at the moment it
  finishes painting: `revealPaint(key, mode)` draws the same grey (pigment
  texture `tWash`, colour, box `uBox`) in the shader, hides the SVG wash in the
  same frame (`washHandoff()`; pixel-checked: within 1–2 levels), then plays
  `uMode` 1–10 over Reveal time (default 1.35s, 25% faster than the first 1.8s): 1 Underpainting (the grey fades out first, by
  24% of the reveal, and the colour soaks in from the inside starting at 13.6%; its front is a smooth sine warp, as noise
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
  (Earlier the old picture stayed while listening and dissolved into the new
  one, with no wash between pictures; the user then asked for the fade-out and
  wash between pictures too.) Tried and dropped: a blue wash for every take; six layered grey blob washes.
- Pictures: watercolor cut-outs drawn by a WebGL canvas covering y 90–590 at
  full width (normal blending, so the Bleed layer stays behind it), each in its box (`PICTURES` in the script).
- Caption: meaning in SF Pro Light 16px at 80%, y 541; Spanish in Regular 28px,
  y 565; colour per word (table above). A miss shows "No te entendí" and the
  transcript in grey. While speaking, the Spanish is typed out live in black, syllable by syllable
  (`showLive()`; real transcripts from the mic, or `syllables()` timed to the
  demo voice, slowing a touch at the end: last syllable +110ms, the one before
  +40ms). The English translation appears a moment after the word: Dad's rises
  in at 220ms, a wrong answer's fades in at 260ms (both by request). When speaking ends the result takes over: wrong answers turn red
  and shake in place, Dad's glare plays (`.from-live`). The Dad caption's lines fade in rising 10u with a
  2px blur that clears (450ms, strong ease-out), the Spanish word 70ms after
  the meaning (`.caption.enter`, `rise-in`); live transcripts don't animate. When Dad is said (correct), the caption is black with no glare
  (the light-blue glare sweep, `.caption.shine`, was removed by request; its CSS
  is still there, unused).
  For the Pope and the potato (wrong answers) there is no glare: the caption
  starts black and quickly changes to the red, which stays (`.caption.redden`).
- Wrong answer (the Pope or the potato): **Edges** only. It responds at once
  (by request, "make it respond to input better"; it used to wait for the
  picture): as soon as the result is in, the caption turns red and shakes, the
  red edges start creeping in (over the grey's exit plus the painting time, so
  they finish with the picture), and the grey wash leaves straight away, even
  mid fade-in (`exitWash(true)`, `washHurry`), so the picture follows quickly.
  The caption stays black (`.red-hold`) until the picture is 50% painted in,
  then turns red (`redNow()`, 350ms) and shakes sideways (`shakeNo()`) at the
  same moment, for both wrong answers (by request; earlier tries: at once,
  15%/25% into the red edges, 80%, then 90%, then 80% again, then 70%, then 55%, now 50% of the picture).
  A soft colour creeps
  in evenly along every side (eased in many small steps) ; the word turns red, the English meaning fades in at 40ms
  (200ms), and both turn red and shake once the picture is 50% in (the `pre-meaning`/`pre-shown` classes are
  left over from when it waited, now unused); the voice button turns 70% opaque so the colour shows
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
  settled on the soft fade). The edges creep in over the same time and
  easing as the picture fades in (painting time, or Reveal time for the ten
  reveal styles; `edgeMs()`), so the two arrive together; the separate Edge
  time slider was removed for that (by request). When leaving (the next take), the red fades out with
  the old picture over 850ms, before the grey wash comes in.
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

Current defaults are the user's second tuned file (2026-10-09 04:07),
settings key `papa-settings-v24`: tooth size −1.49, tooth depth 0.27, warmth
0.1, painting time 1.5s, edge hue 354, edge strength 1.36, edge rim 0; mic
smudges hue 205 / sat 0.75 / light 0.68 / density 0.1 / softness 1.5;
listening blur 3.5; first-picture wash lightness 0.3, strength 0.16, fade
0.5s, blur 0.5, fade-in 0.4s, picture starts at 70% of the fade, reveal time
1s; voice look Pebble (`grey`); reveal style Underpainting. The red edges
run 1.1× faster than the picture, then 10% sooner again (`/ 1.1 * 0.9` in
`finish()`, by request: "make the gradient of the error enter 10% earlier"),
so they show and finish a little before it.

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
  Painting time is adjustable (default 1.5s: 1s, then 1.5s, then 2s, then
  25% faster again by request). A first picture fades in over the whole painting time
  (ease-in-out), in step with the wrong-answer edges. The correct answer
  (Dad) comes in faster, over 0.7s whatever the painting / reveal time
  (`DAD_SEC`, passed to `paint()` / `revealPaint()` as a speed; by request,
  it felt too slow; first tried at half the time, ~0.5s). `tween()` starts its
  clock on the first drawn frame (a first-time texture upload used to stall
  it, so a wrong answer's picture, usually the first of a session, jumped in
  partway and felt harsher than Dad's); the red and the shake start on that
  frame too (`onStart`).
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
    moves the progress dot on, and brings the mic back (`goNext()`). The second
    step asks "Translate / Book" (`WORDS`, `setWord()` crossfades the word); by
    request it's just the title for now, with no Book pictures or recognition.

## Tried and rejected (don't bring back without asking)

- Spreading wash fronts with pale/whitened layers ("white glare"); blooming
  patches; a pen-stroke/hatching reveal of the subject.
- Fading the old picture out before painting the next (rejected early on; the
  user later asked for it together with the grey wash, which is current).
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
