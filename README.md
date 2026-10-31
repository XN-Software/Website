# XN Software

The website for XN Software and its products: Flash, Ember, Riptide and Isola.

A single static page with no build step and no dependencies. Open `index.html` in a browser, or serve the folder:

```
python3 -m http.server 8000
```

- `index.html`: the page.
- `styles.css`: every colour, size and space, from the tokens at the top.
- `main.js`: the video player. Each "Watch the video" button is a plain link to the video; with scripts on, it
  opens in a player on the page instead, loading the video only then.
- `assets/fonts`: Newsreader and XN One, self-hosted, each with its SIL Open Font License.
- `assets/brand`, `favicon.ico`: the icons from the XN Software brand kit.
- `DESIGN.md`: the design rules. Read them before changing anything you can see.

It is ready for GitHub Pages as it is: publish from the root of the default branch.
