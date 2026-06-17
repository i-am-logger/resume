# Résumé — Ido Samuelson

Single source of truth: content in `resume.json` ([JSON Resume](https://jsonresume.org/)
schema), rendered by a custom **Typst** dark-sidebar theme (`resume.typ`) to a
print-perfect, fully offline PDF via Nix.

## Usage

- **Build the PDF:** `nix build` → `result/resume.pdf` (plus `result/index.html`, a web view).
- **Live preview:** `nix run .#live` — recompiles `resume.pdf` on every save of
  `resume.typ` / `resume.json`; open `resume.pdf` in a hot-reloading viewer (e.g. zathura).
- **Dev shell:** `nix develop` — `typst` (with Font Awesome) and fonts on `PATH`.

Edit *content* in `resume.json`; edit *layout/styling* in `resume.typ`. Fonts
(Liberation Sans, DejaVu, Font Awesome 7) and the profile photo (`assets/photo.png`)
are vendored so builds are deterministic and need no network.
