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
4. Push `main` from GitHub Desktop (Push origin).
5. Push `gh-pages` **without switching branches in the project folder** (switching would
   swap all 1,800 project files for the 16 site files and back). Make a small separate
   copy that holds only that branch, and push from it:

   ```bash
   git clone --branch gh-pages --single-branch "file://$PWD" /tmp/tato-game-site
   git -C /tmp/tato-game-site remote set-url origin https://github.com/Nicky-Dimes/tato-game.git
   open -a "GitHub Desktop" /tmp/tato-game-site     # Add Repository, then Push origin
   ```

   Afterwards remove that copy from GitHub Desktop's list (Repository > Remove).
6. Open the play link. A device that has played before picks up the new version the
   next time the page loads.

## First publication (2026-11-11)

Published as a public repository with GitHub Desktop. GitHub turned Pages on by itself
when the `gh-pages` branch arrived. Checked afterwards: the play link returns the title
screen with no console errors in a desktop browser, the served `index.pck` has the same
SHA-256 as the local build, and the `Tests` workflow passed on GitHub for `main`.
Not checked: iPhone / iPad.

## Notes

- The largest file, `index.pck`, is about 60 MB. GitHub refuses files over 100 MB.
- `.github/workflows/web.yml` can build and publish the site on GitHub instead, but it
  is manual-only and has never been run.
- `.github/workflows/ci.yml` runs the checks on every push to `main`.
