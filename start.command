#!/bin/sh
# Papá o la papa: serve this folder on localhost and open it in Chrome.
# On a Mac, double-click this file in Finder (or run ./start.command in Terminal).
# Close the window, or press Ctrl+C, to stop.
cd "$(dirname "$0")" || exit 1

# first free port from 8000 up
PORT=8000
while (echo > /dev/tcp/127.0.0.1/$PORT) >/dev/null 2>&1 || nc -z 127.0.0.1 $PORT >/dev/null 2>&1; do PORT=$((PORT + 1)); done
URL="http://localhost:$PORT/"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 isn't installed. On a Mac, run: xcode-select --install   (then try again)"
  exit 1
fi

# open the page once the server is up (Chrome if it's installed, otherwise the default browser)
( sleep 1
  if [ "$(uname)" = "Darwin" ]; then open -a "Google Chrome" "$URL" 2>/dev/null || open "$URL"
  else xdg-open "$URL" >/dev/null 2>&1 || true; fi ) &

echo "Papá o la papa is running at $URL"
echo "Allow the microphone when Chrome asks. Close this window or press Ctrl+C to stop."
exec python3 -m http.server "$PORT" --bind 127.0.0.1
