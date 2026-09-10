# Thymer editable vector concept

- [SVG master](thymer-dial.svg)
- [512px preview](thymer-dial.png)
- [64px check](thymer-dial-64.png)
- [32px check](thymer-dial-32.png)

The SVG implements the reviewed 204° / 72° / 84° composition as editable paths,
with a shared center and solid fills. It contains no raster images, gradients,
filters, shadows, or fonts. Named Inkscape layers separate dial sectors, Work hand,
Cycle hand, and the white center. The page is 512 × 512 with an outer radius of 192.

Workflow: constructed from numeric SVG geometry after Inkscape's GTK controls did
not reliably receive CUA pointer actions; opened and inspected in Inkscape via CUA.
Previews were exported by Inkscape's own command-line interface. This was not
entirely mouse-drawn. PNG previews use an opaque white background.

At 32px the fine hands are weak. This master is for owner review and larger brand
placements, not an approved menu-bar glyph. No installed app icon was replaced.

## Optical small-size versions

- [32px SVG](thymer-dial-small-32.svg) · [32px PNG](thymer-dial-small-32.png)
- [64px SVG](thymer-dial-small-64.svg) · [64px PNG](thymer-dial-small-64.png)

Both preserve the master geometry and colors, with hands drawn at 1.5 output pixels
and endpoint circles at 3 output pixels. The independent logo reviewer inspected
both actual exports and accepted them as improved small-size color concepts.
These are not the monochrome menu-bar glyph or a declaration of brand adoption.

The owner subsequently confirmed direct SVG editing plus background rendering,
with UI used only for final inspection when needed. No further UI manipulation
was performed after that instruction. The previously observed unsaved blank
Inkscape document was not closed or discarded; unrelated documents were preserved.
