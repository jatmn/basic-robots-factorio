# Pullfrog owner commands and reviews

For manual commands, **jatmn** creates a new top-level issue or PR comment
whose first line begins with `@pullfrog` and a visible instruction:

```text
@pullfrog review this PR and report actionable defects
```

Other commenters, passive or quoted mentions, bare mentions, edited comments,
inline review comments and workflow reruns cannot run the agent. Post a new
command to retry. The workflow checks GitHub's actor identity and jatmn's account
ID, `12479882`, then checks out the trusted default branch. The Python helper
verifies the repository, event and original comment before the agent receives
credentials. The verified owner role lets commands manage contributor-created
issues and PRs too.

The **CI** dispatcher runs authorization tests in its Python job and workflow
validation in its actionlint job; these validation jobs never launch the agent.

## Automatic reviews

Pullfrog reviews new PRs, drafts, and updated diffs in this public repository
when GitHub identifies `jatmn` as the PR author. The person pushing an update
can be a different account. The GitHub App dispatches the workflow on the
default branch and the author check must pass before the agent starts.
In Pullfrog settings, enable PR reviews, draft reviews, and re-reviews on new
commits, and disable managed mentions and external-contributor reviews.
Use a fresh owner-authored draft and push an update after the workflow is
merged to verify live automatic dispatch.

## Maintenance and checks

The action bootstrap is pinned to Pullfrog v0.1.122; its npm runtime accepts
compatible 0.1.x updates. Keep `PULLFROG_VERSION` in the helper aligned with the
bootstrap (`tools/test_pullfrog_command.py` fails if they differ) and verify the
upstream payload contract when updating it. Large commands use the original
GitHub event snapshot on the same runner, preserving the authorized comment even
if it is subsequently edited on GitHub.

```sh
python3 tools/test_pullfrog_command.py
actionlint
git diff --check
```
