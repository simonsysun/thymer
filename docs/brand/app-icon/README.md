# Thymer app icon

The owner approved the three-sector vector proportions and requested an app-icon presentation using image generation. This concept adds a cool rounded-square tile, inset spacing and a subtle perimeter shadow, retaining the complete blue/green/white dial and unequal hands.

![App icon concept](thymer-app-icon-v1.png)

- [Image](thymer-app-icon-v1.png)
- [Exact prompt](generation-prompt.txt)
- Structural reference: [vector master](../vector/thymer-dial.svg)

Generated with the built-in imagegen tool. OpenAI announced Images 2.5 availability in Codex, but this tool has no model selector and returned no per-call model identity; the precise backend version is unverified. No claim is made that a particular 2.5 variant was selected.

Approved for the application on 2026-09-09. `scripts/build.sh` converts this PNG into the standard macOS icon sizes (16–1024 pixels), packages `AppIcon.icns`, and registers it in the app bundle before signing. The approved artwork, including its background and slight tonal variation, is preserved. The SVG remains the structural design reference.
