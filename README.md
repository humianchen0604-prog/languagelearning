# Papá o la Papa

A one-screen prototype: the prompt is **Dad**, and you say it in Spanish.
What you actually pronounce gets painted into the frame in watercolor washes:

| You say   | It paints  |
|-----------|------------|
| el Papa   | the Pope   |
| la papa   | a potato   |
| papá      | Dad        |

## Run it

The microphone needs a real web address (not a double-clicked file):

```sh
cd papa
python3 -m http.server 8000
# open http://localhost:8000 in Chrome or Safari, allow the mic
```

Speech recognition uses the browser's built-in Spanish (Mexico) model.
Where it isn't available, tapping the mic shows the three words to tap instead.

## Files

- `index.html` — the whole prototype (paper, icons, voice pad, WebGL watercolor painter, Adjust panel)
- `assets/pope.jpg`, `assets/potato.jpg` — watercolor art
- `assets/dad.jpg` — **stand-in**; replace with the real portrait (3:4, e.g. 816 × 1088)
- `assets/fonts/UglyDuck.woff2` — **add this**; the page uses the Ugly Duck font from here (or from your installed fonts) and falls back to Kalam until then
