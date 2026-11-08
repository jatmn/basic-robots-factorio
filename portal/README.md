# Mod Portal page

This folder is the mod's page on the [Factorio Mod Portal](https://mods.factorio.com/mod/basic-robots-f2).
Each release brings the live page in line with it. Nothing here goes into the mod package.

| File | On the portal |
| --- | --- |
| `summary.txt` | The short summary, shown in mod listings and search. 500 characters at most |
| `description.md` | The long description on the mod's page, in Markdown |
| `gallery/` | The screenshot gallery, in filename order (`01-…`, `02-…`). PNG or JPEG, 5 MiB at most each |
| `README.md` | This file. Not published |

The contents were copied from the live page when this folder was added, so the first sync
changes nothing. `gallery/01-thumbnail.png` is the mod's `thumbnail.png`.

## Writing the description

Link to files in this repository with paths relative to this folder, such as
`images/robots.png` or `../docs/releases.md`, so the page previews correctly on GitHub.
For the portal, `tools/portal_page.py` turns them into GitHub URLs pinned to the release
commit: pictures (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) as raw image URLs, other files
as GitHub pages.

- Use inline links (`[text](path)`). Reference-style links and paths with spaces are refused.
- Every linked file must be committed, or GitHub can't serve it.
- The portal doesn't render HTML, so use Markdown only.

## The gallery

The portal names images by their SHA-1, so an unchanged file is never uploaded again and
renaming files only changes their order. Removing a file removes it from the live gallery
at the next sync. While `gallery/` is empty or missing, the live gallery is left alone.

## Checking and previewing

```sh
cd tools
python3 portal_page.py --check                  # the rules above; CI runs this too
python3 portal_page.py --check --print          # the summary and description as the portal will get them
python3 portal_page.py --tag v0.3.1 --dry-run   # what a sync would change on the live page (no API key needed)
```

## How it reaches the portal

The **Release Please** workflow uploads a release's ZIP to the portal, then runs
`python3 tools/portal_page.py --tag <tag>` from the same release commit, before the GitHub
release is published. It changes only what differs: the summary and description through the
[Mod details API](https://wiki.factorio.com/Mod_details_API), and the gallery through the
[Mod images API](https://wiki.factorio.com/Mod_images_API). An unchanged page sends nothing.
Changes here reach the portal with the next release. See [docs/releases.md](../docs/releases.md).
