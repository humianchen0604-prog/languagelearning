# Papá o la papa

A one-screen prototype (design: Figma "Side-project"): the screen says **Translate / Dad**, and you say it in Spanish.
What you actually pronounce gets painted onto the page in watercolor, with a caption:

| You say   | It paints  |
|-----------|------------|
| el papa   | the Pope   |
| la papa   | a potato   |
| papá      | Dad        |

## Run it on your computer (localhost)

The microphone needs a real web address (not a double-clicked `index.html`).

**One click (Mac):** double-click `papa/start.command` in Finder. It serves the
folder on `http://localhost:8000` (or the next free port) and opens it in Chrome.
Close the Terminal window to stop it.

**By hand:**

```sh
cd papa
python3 -m http.server 8000
# open http://localhost:8000 in Chrome or Safari, allow the mic
```

Speech recognition uses the browser's built-in Spanish (Mexico) model.
Where it isn't available, tapping the mic shows the three words to tap instead.
The Adjust panel tunes the paper, the image edges, painting time and the voice blob's look.

Published preview (tap words only, no mic): https://claude.ai/artifact/MrvbqSWJfhkj1HsnJr35ku

Design notes and decisions for future work: `CLAUDE.md`.

## Files

- `start.command`: serves the folder on localhost and opens it in Chrome
- `index.html`: the whole prototype (paper, icons, voice blob, WebGL watercolor painter, Adjust panel)
- `assets/*-cutout.png`: the three pictures, split from `assets/pictures-source.webp` with a soft blur toward the bottom
- `assets/{pope,potato,dad}.jpg` and `assets/*-mask.png`: older full watercolors (not used by the page)
- Type is SF Pro (system font), as in the Figma design
