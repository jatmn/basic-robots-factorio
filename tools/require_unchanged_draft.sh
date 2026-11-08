#!/usr/bin/env bash
# Stop unless TAG is still the unpublished draft recorded at RELEASE_SHA, and any
# existing Git tag of that name resolves to that commit (annotated tags included).
# Run before every external write: the Mod Portal steps and each GitHub write.
set -euo pipefail
gh release view "$TAG" --json isDraft,targetCommitish,tagName > "$RUNNER_TEMP/release.json"
jq -e --arg tag "$TAG" --arg sha "$RELEASE_SHA" \
  '.isDraft == true and .tagName == $tag and .targetCommitish == $sha' "$RUNNER_TEMP/release.json"
gh api "repos/$GH_REPO/git/matching-refs/tags/$TAG" > "$RUNNER_TEMP/tag-refs.json"
tag_ref=$(jq -r --arg ref "refs/tags/$TAG" \
  '.[] | select(.ref == $ref) | .ref' "$RUNNER_TEMP/tag-refs.json")
if [ -n "$tag_ref" ]; then
  tag_sha=$(gh api "repos/$GH_REPO/commits/$tag_ref" --jq .sha)
  [[ "$tag_sha" == "$RELEASE_SHA" ]]
fi
