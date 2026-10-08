# Papá o la Papa

A one-screen prototype (design: Figma "Side-project"): the screen says **Translate / Dad**, and you say it in Spanish.
What you actually pronounce gets painted onto the page in watercolor, with a caption:

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
The Adjust panel tunes the paper, the image edges, painting time and the voice blob's look.

Published preview (tap words only, no mic): https://claude.ai/artifact/MrvbqSWJfhkj1HsnJr35ku

Design notes and decisions for future work: `CLAUDE.md`.

## Files

- `index.html`: the whole prototype (paper, icons, voice blob, WebGL watercolor painter, Adjust panel)
- `assets/*-cutout.png`: the three pictures (stand-ins made from the watercolors below until the Figma images are downloaded)
- `assets/{pope,potato,dad}.jpg` and `assets/*-mask.png`: source watercolors and their traced outlines
- Type is SF Pro (system font), as in the Figma design
