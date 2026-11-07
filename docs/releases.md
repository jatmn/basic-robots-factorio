# Releasing Basic Robots - Factorio 2.1

The **Release Please** workflow maintains a **draft release PR** on `main`.
Continue merging normal changes and adding player-facing entries to
`changelog.txt` while that PR is open. No release is published until you mark
the release PR ready and merge it.

## First release: 0.3.1

The empty manifest means Release Please has not published this repository yet.
The first proposed version is fixed at 0.3.1, matching the current
author-maintained changelog, even if more features arrive before release.
0.3.0 was uploaded to the Mod Portal manually before this automation existed,
so the first automated release starts after it. The bootstrap boundary is
[831ec03a1b281eee73332ef575d94c1a714f8347](https://github.com/jatmn/basic-robots-factorio/commit/831ec03a1b281eee73332ef575d94c1a714f8347),
the last default-branch commit at version 0.2.1 before the current
version's changes. Earlier history is excluded. The PR summary includes only
recognized Conventional Commits after that boundary; it does not reconstruct
older nonconventional commit messages. Published player-facing notes always
come from the matching authored changelog section.
After the first release, Release Please uses its published release and manifest
to calculate subsequent versions from Conventional Commits. There is no
permanent `release-as` override to remove.

Release Please updates `info.json`, `.github/version.txt` and
`.github/.release-please-manifest.json` in its PR. It does **not** rewrite
`changelog.txt` or create a second generated changelog. Its PR body summarizes
Conventional Commits; published release notes use only the matching newest
author-written section of `changelog.txt`.

## Maintainer sequence

1. Merge normal PRs using Conventional Commit titles (`fix:`, `feat:`, etc.).
   Authors add entries to the current unreleased section of `changelog.txt`.
2. Inspect the draft release PR, including the proposed version. For subsequent
   releases, create/update the newest changelog section to match that version
   and keep the release date current. The historic `info.json.date` field is
   descriptive metadata; Factorio does not require it for loading.
3. Mark the release PR ready, review checks and merge when ready to publish.
   Keep Release Please's branch, title/body structure and autorelease labels.
4. The workflow creates an unpublished GitHub draft, checks out the exact
   release merge commit, requires tag/manifest/metadata/changelog agreement,
   builds and validates the ZIP, uploads that ZIP to the Factorio Mod Portal when
   connected (see below), uploads it with `SHA256SUMS`, and publishes.
   Older changelog sections remain inside the mod but are absent from that
   GitHub release's notes.

Download the release asset **`basic-robots-f2_0.3.1.zip`** (or the corresponding later
version) and copy it unchanged into Factorio's mods directory. GitHub's automatic
**Source code** archives are not the installable asset. For a source checkout,
use the unversioned folder **basic-robots-f2**. See [info.json](../info.json) for the
current mod version, Factorio series and dependency constraints. Install required
dependencies separately; this ZIP does not bundle other mods.
This automation preserves the declared Factorio **2.1** target.

## Factorio Mod Portal publishing

Publishing to the [Mod Portal](https://mods.factorio.com/mod/basic-robots-f2) is
optional. With no `FACTORIO_API_KEY` secret, the portal step notes that it is not
connected and the GitHub release proceeds as before. To enable it, create an API key
on your [Factorio profile](https://factorio.com/profile) with the **Upload Mods** and
**Edit Mods** permissions and store it as the repository Actions secret
`FACTORIO_API_KEY`. Merging a release PR then authorizes the portal upload and page
sync too.

`tools/publish_mod.py` uploads the same validated ZIP that the GitHub release gets.
It uses the API key only to request an upload URL, never sends the key to that URL,
and then verifies the portal's filename and SHA-1, reading the listing past the
portal's 15-minute CDN cache. A portal version with identical bytes counts as
already published, unless the portal also has a newer version; different bytes for
that version, or any newer portal version, stop the release without uploading. A
version reaching the portal outside this workflow therefore leaves an older draft
unpublished; check the portal and finish that GitHub release by hand. The listing already exists (0.3.0 and earlier
were uploaded manually); the uploader does not create a listing or change its licence.

After the upload, `tools/portal_page.py` brings the portal page in line with
[`portal/`](../portal/README.md): the summary, the Markdown description and the
screenshot gallery. It changes only what differs and sends nothing when the page is
unchanged. Relative links in the description become GitHub URLs pinned to the release
commit. It refuses a version older than the portal's newest release or one not uploaded
yet. CI runs `tools/portal_page.py --check`. Preview a sync without a key:

```sh
cd tools && python3 portal_page.py --tag vX.Y.Z --dry-run
```

Both portal steps run before the GitHub release leaves draft. A portal failure
therefore leaves the release unpublished, and the retry below resumes the portal
upload, the page sync and the GitHub publication together. Once a version is on the
portal, do not abandon its draft with the procedure below: the portal will not accept
different bytes for that version. Retry instead. The portal API is tested only with
simulated responses (`tools/test_publish_mod.py`, `tools/test_portal_page.py`); the
first real upload happens on the first release merged after the key is added.

## Release failures and recovery

The first version (0.3.1) follows the manually uploaded Mod Portal 0.3.0, so it does
not reuse a published version.

The workflow trusts code merged into `main`, including the release tooling.
Credentials are scoped to API steps, and checkout does not persist them.
Steps share a runner; these scopes do not sandbox malicious merged code.

Build, portal and upload failures leave the release unpublished. Fix transient problems,
then run **Release Please** manually on **main**, with `retry_tag` set to the
existing draft tag (for example `v0.3.1`). This rebuilds its recorded commit,
replaces incomplete assets and publishes only after validation. An already
published release is rejected. Normal runs pause while a versioned release
draft remains unpublished, so they cannot propose another release using that
unfinished release's history. Retry never substitutes newer main-branch code.
A blank manual input resumes normal Release Please operation.

Normal runs and retries have separate workflow admission groups and share one
release job lock. A later push cannot replace an admitted retry waiting for that
lock. Within either admission group, a newer pending run can still replace an
older pending run; this is not a durable queue of every manual request.

Do not manually publish or edit the release while its workflow is running.
The workflow rechecks the draft status, tag and exact build commit
(`tools/require_unchanged_draft.sh`) before the Mod Portal steps, before uploading
GitHub assets and again before publishing, stopping if they changed.
An existing Git tag must also resolve to that commit, including annotated tags.
A missing tag is normal for a draft; GitHub creates it on publication.
These checks do not lock GitHub's release UI or make the check and write atomic;
workflow concurrency only serializes workflow runs, not manual edits.

### Abandon an unpublished release with a source defect

If the recorded commit cannot build or validate, a retry cannot repair it.
Use this maintainer-controlled recovery to propose a corrected release.
Its version is recalculated from all changes since the last published release;
new feature or breaking changes can increase it beyond the failed version.
The first automated release remains 0.3.1 because of `initial-version`.
Do not use this procedure for a release that was published.
Wait for any active Release Please run to finish and do not dispatch retries
during recovery.

1. Record the failed tag, its merged release PR number and merge SHA. For
   example, inspect the draft with:

   ```sh
   gh release view v0.3.1 --repo jatmn/basic-robots-factorio \
     --json isDraft,targetCommitish,tagName
   ```

   Require `isDraft: true` and require `targetCommitish` to equal the failed
   release PR's merge SHA. Stop if either differs. The PR is already merged;
   do not try to reopen it.
2. On that failed release PR, remove `autorelease: pending` if present and
   retain/add `autorelease: tagged`. Release Please normally made this label
   transition when it created the draft, before our build ran. Removing any
   leftover pending label prevents it from recreating the abandoned release.
3. Open a normal corrective PR against `main`, containing the source fix and
   restoring `.github/.release-please-manifest.json` to the last **actually
   published** release. For a failed first 0.3.1 release with nothing published,
   replace the file with `{}`. If 0.3.1 was published and 0.3.2 failed, replace
   it with `{".": "0.3.1"}`. Determine that previous version from the published
   GitHub release and its tag, not from the advanced manifest or `info.json`.
   Leave `info.json`, `.github/version.txt` and the newest authored changelog
   section at the failed version for now; step 5 reconciles the new proposal.
   Use a `fix:` corrective PR title and review
   and merge the correction. Leave the failed draft in place during this step:
   the normal workflow is expected to stop at its unpublished-draft guard.
4. Recheck that the failed release is still a draft at the recorded SHA, then
   delete only that draft. This workflow does not force-create draft tags, so
   a failed draft normally has no Git tag:

   ```sh
   gh release delete v0.3.1 --repo jatmn/basic-robots-factorio
   ```

   If a tag with that exact name exists, first verify that it resolves to the
   recorded failed SHA with `gh api repos/jatmn/basic-robots-factorio/commits/v0.3.1 --jq .sha`.
   Only when it matches, add `--cleanup-tag` to the delete command above to
   remove both. An unexpected tag target requires investigation, not deletion.
5. Run **Release Please** manually on **main** with `retry_tag` **blank**.
   The retired PR's labels prevent replay; the restored manifest makes Release
   Please propose a new draft PR from the previous published boundary, or the
   original bootstrap boundary for the first release. Inspect the replacement
   PR's calculated version. For example, after published 0.3.1 and failed 0.3.2,
   a new `feat:` can make the replacement 0.4.0. Before merging, update the
   newest authored changelog section to that final proposed version and include
   all unreleased changes. Verify that the PR's manifest, `info.json`, version
   file and changelog agree; rerun release preparation on the PR checkout.
   Recheck this agreement after further normal merges update the proposal.
   Mark ready and merge only when the correction is ready.
   That new release PR merge supplies the new immutable packaging commit.

Deleting only the draft is insufficient: leaving the advanced manifest can
skip the intended version or reuse the wrong history. No published release or
tag is removed by this procedure. The [GitHub CLI release-delete documentation](https://cli.github.com/manual/gh_release_delete)
describes the optional tag cleanup.

Local release preparation, on a release PR checkout where the manifest already
contains the proposed version:

```sh
python3 tools/test_prepare_release.py
python3 tools/prepare_release.py --tag v0.3.1
```

The `tools/package.py` / `tools/validate_package.py` commands
build development ZIPs without requiring a merged release manifest.

## Verified requirements and sources

- [Factorio 2.1.24 mod structure](https://lua-api.factorio.com/2.1.24/auxiliary/mod-structure.html):
  ZIP filename `{name}_{version}.zip`, one enclosing mod folder with
  `info.json`, matching name/version, mandatory name/version/title/author,
  version components in 0–65535 and an explicit major/minor `factorio_version` matching the intended game series.
  The enclosing folder's name is unrestricted by Factorio; our builder uses
  `basic-robots-f2_<version>/` consistently. Dependencies in `info.json` also apply.
- [Factorio changelog format](https://lua-api.factorio.com/2.1.24/auxiliary/changelog-format.html):
  the in-game history uses 99-dash separators, version lines, two-space
  categories and four-space bullet entries. Existing historical text is
  preserved. Release preparation checks the current section/version; it does
  not claim to lint every historical entry.
- [Release Please bootstrap and manifest configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
  and [configuration schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json):
  initial version, bootstrap boundary, draft PR/release settings and JSON updates.

ZIP validation checks tracked membership, exact source bytes, required notices,
CRC and checksum. It does not replace Factorio engine, save or graphics testing
for gameplay changes.
