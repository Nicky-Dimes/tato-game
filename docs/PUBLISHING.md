# Publishing

Repository: `https://github.com/Nicky-Dimes/tato-game` (public; all rights reserved, see
`LICENSE.md`). Play link: `https://nicky-dimes.github.io/tato-game/`.

## How the play link works

GitHub Pages serves the **`gh-pages` branch**. That branch holds nothing but the web
export (`index.html`, `index.js`, `index.wasm`, `index.pck`, icons), exactly as built
and checked on the development Mac. The source code lives on `main`.

## Publishing a new version

1. On `main`: `tools/check.sh` must pass, then `tools/build.sh web`.
2. Try it: `python3 -m http.server 8780 --directory build/web` and open
   `http://localhost:8780` (or `python3 tools/serve_https.py` for a phone on Wi-Fi).
3. `tools/publish_site.sh` records `build/web` as a new commit on the local `gh-pages`
   branch. It does not switch branches or touch the project files, and it does not push.
4. Push `main` and `gh-pages` (GitHub Desktop: switch to the branch, Push origin).
5. Open the play link. A device that has played before picks up the new version the
   next time the page loads.

## Notes

- The largest file, `index.pck`, is about 60 MB. GitHub refuses files over 100 MB.
- `.github/workflows/web.yml` can build and publish the site on GitHub instead, but it
  is manual-only and has never been run.
- `.github/workflows/ci.yml` runs the checks on every push to `main`.
