# Pullfrog owner commands

Pullfrog runs only after **jatmn** creates a new top-level issue or PR comment
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

Opening a PR or marking it ready for review must not launch Pullfrog. Its agent
workflow has no PR, push, schedule or `workflow_dispatch` trigger. The separate
**CI** dispatcher runs authorization tests in its Python job and workflow
validation in its actionlint job; these validation jobs never launch the agent.

## Maintenance and checks

The action bootstrap is pinned to Pullfrog v0.1.111; its npm runtime accepts
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
