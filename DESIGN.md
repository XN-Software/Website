# XN Software design rules

How XN Software looks, reads and moves. One page for everyone who touches the site, a product page, a README banner
or a launch image. When something here and a mockup disagree, this file wins; when this file is wrong, change it
first, then the work.

## The idea

**Quiet, warm, made by hand.** XN makes free, open source, local-first software to help you *build beyond*. The design should feel like that:
paper, ink and one warm colour, set like a good book. Confidence comes from type and space, not effects.

Three tests for anything new:

1. **Would it look right printed?** If it only works because it glows, blurs or moves, it is decoration.
2. **Does every element earn its place?** Remove it and see what is lost. If nothing, leave it out.
3. **Does it sound like a person?** Copy is written the way you would explain the product to a friend.

## Never

- Purple, violet or rainbow gradients. Any gradient used as a background.
- Inter, or any default UI sans used for everything.
- Glassmorphism, glows, neon, drop shadows that float cards off the page.
- Stock icon packs, 3D blobs, abstract "AI" swirls, robot or brain imagery.
- Emojis in product copy. Em dashes anywhere.
- Hype words: revolutionary, seamless, supercharge, unleash, game-changing, next-gen.
- Naming other companies' AI products to explain ours.
- Text in all caps longer than three words.

## Colour

Paper and ink, with one accent. Colour is used to point, not to decorate.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `--paper` | `#F4F1EA` | `#1B1A17` | Page background |
| `--paper-2` | `#ECE8DE` | `#232220` | Raised areas: plates, the video frame |
| `--ink` | `#1E1D1A` | `#ECE8DF` | Headings and body text |
| `--ink-2` | `#5E5A52` | `#A9A397` | Secondary text, captions |
| `--ink-3` | `#6C675D` | `#8C867A` | Labels, numbers, quiet details |
| `--rule` | `#D9D3C6` | `#36342F` | Hairlines and borders |
| `--clay` | `#A4502F` | `#DB7B57` | The accent: links, the main button, one detail per drawing |

Rules:

- The accent covers less than 5% of any screen. One accent element per view is ideal; three is the limit.
- Text is never pure black on pure white. Body text on `--paper` is `--ink`; anything quieter is `--ink-2`.
- Dark mode is a different paper, not an inverted page. The accent gets lighter to keep its contrast.
- Every text colour pair passes WCAG AA (4.5:1 for body, 3:1 for text 24px and up). On `--paper`, light: `--ink` 14.9:1, `--ink-2` 6.1:1, `--ink-3` 5.0:1, `--clay` 4.9:1. Dark: 14.2, 6.9, 4.8 and 5.8:1.

## Type

Two families, each with one job.

- **Newsreader**, a variable serif with optical sizes, carries every word you read: headlines, product names,
  paragraphs, lists. Self-hosted in `assets/fonts/newsreader` (OFL).
- **XN One**, our own rounded geometric sans, the face of the logo, is used *a little*: labels and section numbers,
  navigation, buttons, the footer and the video player's title. Never for a headline or a paragraph. Self-hosted in
  `assets/fonts/xn-one` (OFL). It covers letters, digits and basic punctuation only; anything else (a middle dot,
  a copyright sign) falls back to Newsreader on its own.

| Role | Size (desktop / phone) | Face, weight | Leading | Notes |
| --- | --- | --- | --- | --- |
| Display | 76 / 44px | Newsreader 400 | 1.02 | Hero only. Tracking -0.02em. One italic phrase allowed, in `--clay`. |
| Heading 1 | 52 / 36px | Newsreader 400 | 1.08 | Product names. |
| Heading 2 | 32 / 26px | Newsreader 400 | 1.15 | Section titles. |
| Lead | 22 / 19px | Newsreader 400 | 1.45 | The paragraph under a heading. `--ink-2`. |
| Body | 18 / 17px | Newsreader 400 | 1.6 | Measure 60 to 70 characters. |
| Label | 13px | XN One 400 | 1.3 | `--ink-3`, tracking 0.06em. Section numbers and meta. |
| Navigation | 14px | XN One 400 | 1 | `--ink-2`, tracking 0.03em. |
| Button | 15px | XN One 400 | 1 | Sentence case, tracking 0.02em. |

Rules:

- Headings are regular weight. Size and space make them important, not bold.
- Italic is for emphasis and for the one expressive phrase in a headline, like *build beyond*. Never for a whole paragraph.
- Sentence case everywhere: headings, buttons, navigation.
- No text smaller than 13px. Line length never over 72 characters.

## The logo

- Use the files from the brand kit as they are: the lockup (the XN mark plus "Software") in the header, the mark on
  its own where space is small, the rounded icon for favicons and app icons.
- Black on light, white on dark. On the site it is drawn in `--ink`, so it follows the theme. Never in `--clay`,
  never in a gradient, never outlined, stretched or rotated.
- Clear space around it at least half the mark's height. The lockup is never smaller than 16px tall, the mark never
  smaller than 12px.
- Our line is **Free to use, open to read, yours to keep.** Free, open source and local first, in that order. It sits
  beside the mark in the footer and closes anything we make, like a launch film. Say it exactly; don't shorten it.

## Space and layout

- An 8px base. Use 8, 16, 24, 32, 48, 64, 96, 144.
- Content width 1120px, reading width 680px, side gutter 24px on phones and 48px from tablets up.
- Sections are separated by space and a single hairline, never by a change of background colour.
- Products sit on a two-column grid on desktop (words left, plate right, alternating), one column on phones with the
  plate first.
- Align to the left. Centre only a single short line, like the footer.

## Drawings

Each product has a plate: a simple line drawing of the thing itself, in `--ink` on `--paper-2`, with exactly one
detail in `--clay`.

- Ember: a watch with a single record dot.
- Riptide: a timeline with keyframes along an easing curve.
- Flash: a terminal prompt with a plan being ticked off.
- Isola: the island at the top of a screen, with one live activity.

Lines are 1.5px at 1x, round caps and joins, no fills except the accent detail. Drawings are inline SVG, use
`currentColor`, and carry a text alternative.

## Components

**Buttons.** Two kinds only.
- *Primary:* `--ink` background, `--paper` text, 999px radius, 12px by 20px padding. On hover the background becomes
  `--clay`. Used once per product: "Watch the video".
- *Quiet:* text with an underline offset 4px, `--ink`; the underline turns `--clay` on hover. Used for "View on
  GitHub" and everything secondary.
- A product without a video yet shows the primary button disabled, with "Video coming soon", at 50% opacity, not
  clickable, with `aria-disabled`.

**Links** in body text are underlined, always. Colour alone never marks a link.

**Plates** have a 4px radius, no shadow, and a 1px `--rule` border.

**The video player** opens in a `<dialog>` over a `--paper` backdrop at 92% opacity. Wide videos are 16:9, Shorts
9:16. Escape, the close button and a click outside all close it, and focus returns to the button that opened it.
Every "Watch the video" button is a real link to the video first, so it works with scripts off.

## Motion

- Motion confirms something happened. It never performs.
- Fades and short moves only: 160ms for hover, 240ms for opening, `cubic-bezier(.2, .7, .2, 1)`.
- Nothing moves on its own, loops, or reacts to scroll position. One exception: the hero's "build beyond" is typed in
  once on load, with a cursor that blinks while it types and then goes. Not repeated, and not with reduced motion.
- With `prefers-reduced-motion`, all transitions are off.

## Writing

- Say what it does, then why you'd want it. "Raise your wrist, say the idea, and it's kept." Not "Next-generation
  idea capture."
- Short sentences. Active voice. Second person: the reader is "you".
- Product names are plain words: Flash, Ember, Riptide, Isola. Never in all caps, never with a trademark sign.
- One idea per paragraph. Three bullet points at most under a product.
- Numbers are digits ("25 widgets"), units are spelled out where they're words ("seconds", not "secs").
- No em dashes: use a colon, a comma or a full stop.

## Accessibility

- Everything works with a keyboard, with a visible focus ring: 2px `--clay`, offset 3px.
- Headings go in order. Each section has a heading, even if it is visually small.
- Videos load only when asked for, and never autoplay with sound.
- The page is readable and usable at 200% zoom and at 320px wide.

## Checklist before shipping

- [ ] No gradient, no glow, no Inter.
- [ ] Newsreader for reading, XN One only for the small parts, the logo from the kit.
- [ ] One accent per view, at most three.
- [ ] Every text pair passes AA in light and dark.
- [ ] Works without JavaScript (video buttons link out).
- [ ] Works at 320px, with no sideways scroll.
- [ ] Copy has no em dashes, emojis or hype words.
