# XN Software

The website for XN Software and its products: Flash, Ember, Riptide and Isola.

A single static page with no build step and no dependencies. Open `index.html` in a browser, or serve the folder:

```
python3 -m http.server 8000
```

- `index.html`: the page.
- `styles.css`: every colour, size and space, from the tokens at the top.
- `main.js`: the video player, and the download buttons. Each "Watch the video" button is a plain link to the video;
  with scripts on, it opens in a player on the page instead, loading the video only then. Each Download button offers
  the visitor's own system, and the line under it the other two.
- `assets/downloads`: Riptide's and Isola's downloads: a Windows `.exe`, a zipped macOS app and (Riptide only, as
  Isola has no Linux version) a Linux script. Each runs
  Riptide's own installer, shows what it says in a window of its own as it says it (Windows Forms, Cocoa, or zenity
  or Tk on Linux), and pops up when it is done. Flash's are on flashproject.dev, where its Download button goes. The
  sources are in `installers/`; `installers/build.sh` (Go and Python 3) builds both apps' downloads, writing Flash's
  into the Flash-Site repository checked out beside this one. Where an app has a dev version, the installer asks.
- `assets/fonts`: Newsreader and XN One, self-hosted, each with its SIL Open Font License.
- `font/`: XN One's page: the letters, the weights, a type tester, examples in use, and its download
  (`assets/downloads/xn-one.zip`: TTF and WOFF2 with the license).
- `brand/`: the brand kit's page: the logo files, colours, type and rules, and the whole kit as
  `assets/downloads/xn-brand-kit.zip`.
- `assets/brand`, `favicon.ico`: the brand kit's files: the lockup and the mark in black and white (SVG and PNG), and
  the icon, dark and light.
- `DESIGN.md`: the design rules. Read them before changing anything you can see.

It is ready for GitHub Pages as it is: publish from the root of the default branch.
