# Portfolio

A responsive Flutter web portfolio. **All content comes from one Markdown file:
[`assets/content.md`](assets/content.md).** Edit it, push, and the site redeploys.

## Editing content

Open `assets/content.md`. The rules are in the comment at the top of the file;
in short:

| Markdown | Becomes |
|---|---|
| `# Name` + `**Role**` + `> tagline` | Hero header |
| `## Highlights` with `- **6+** Years…` | Stat cards in the hero |
| `## …Summary` / `## About` | Paragraphs |
| `## …Skills` with a `\| Category \| a, b, c \|` table | Skill cards |
| `## …Experience` with `### Company — Dates`, `*Role*`, bullets | Job cards |
| `## …Projects` with `- **Title** (Category) — text [link](url)` | Project grid (`### Group` adds filter chips) |
| `## Open-Source…` with `- **package** – text` | pub.dev package cards |
| `## Education` with `### Degree — Dates` | Education cards |
| `## Certifications` / `## Awards` | Simple list |
| `## Contact` with `- Email:`, `- Location:`, `- Resume:`, `- Coffee:`, `- Any Label: url` | Contact buttons (Coffee adds a Buy Me a Coffee pill) |
| Any other `## Heading` | Plain text section |

Sections appear in the order you write them. Search the file for `TODO` to find
the placeholders you still need to fill in.

**Resume download:** upload the PDF to Google Drive, set sharing to "Anyone with
the link", and paste the share link on the `Resume:` line in the Contact section
(uncomment it). It is converted to a direct download. A `resume.pdf` in `web/`
also works.

**Link previews & search:** `tool/web_meta.dart` runs after the web build (see
the deploy workflow) and fills the page title, description, Open Graph tags and
a hidden text copy of the page from `content.md`. The preview image is
`web/og-image.jpg`.

**Colours:** change `accent` in `lib/theme.dart`.

## Run locally

```sh
flutter pub get
flutter run -d chrome
flutter test        # checks the Markdown still parses as expected
```

## Free hosting on GitHub Pages

1. Create a GitHub repo and push this folder to its `main` branch.
   Name it `<your-username>.github.io` to serve at the root URL, or use any
   other name to serve at `https://<your-username>.github.io/<repo>/`.
2. In the repo, go to **Settings → Pages → Source** and select **GitHub Actions**.
3. Every push to `main` runs `.github/workflows/deploy.yml`, which tests, builds and
   publishes the site.
