# Development checks

This repository uses the same lightweight CI as the other Yuoki mods
([Yuoki](https://github.com/jatmn/Yuoki-Factorio-2.x/blob/main/docs/development.md)).
It runs on pull requests and pushes to `main`. The dispatcher (`.github/workflows/ci.yml`)
reads the complete Git diff with `tools/ci_changes.py` and calls only the affected
reusable workflows; it avoids GitHub's capped event path filters and cancels superseded
runs for the same PR. The router is loaded from the comparison revision, so a PR that
edits it cannot disable its own checks.

A final `CI result` job always runs and fails if any selected check failed or was
cancelled. It is the single check to require in branch rules, because routed jobs are
reported under different names when they run or are skipped.

## Which checks run

| Changed surface | Checks |
| --- | --- |
| Lua | Lua / Luacheck (Lua 5.2 syntax + Luacheck) and Lua / StyLua, plus packaging |
| `.luacheckrc`, `.stylua.toml` or `lua.yml` | Both Lua checks on **every** tracked Lua file |
| Python or `.ruff.toml` | Python AST syntax, Ruff lint and package/release/routing regressions |
| Release Please config, manifest or version file | Python checks |
| Metadata, locale, graphics, changelog and other shipped files | Packaging |
| A workflow | actionlint, Python regressions and the affected validation workflow |
| `ci.yml` or `tools/ci_changes.py` | Everything |
| `docs/` | Change detection only |

PRs check the Lua files they add or modify; pushes to `main` check all tracked Lua files.
Release Please PRs also validate the proposed metadata and authored release notes.

Tool versions: **Lua 5.2**, **Luacheck 1.2.0**, **StyLua 2.5.2**, **Ruff 0.17.3**,
**actionlint 1.7.12**. Factorio stage globals are declared in `.luacheckrc`; Ruff
enforces only correctness rules, E9 + Pyflakes (syntax errors, undefined names, unused
imports/variables), configured in `.ruff.toml`.

## Local commands

Run from the repository root:

```sh
git diff --check
git ls-files -z -- '*.lua' | xargs -0 -r -n1 luac5.2 -p --
git ls-files -z -- '*.lua' | xargs -0 -r luacheck --
git ls-files -z -- '*.lua' | xargs -0 -r stylua --check --config-path .stylua.toml --
ruff check --config .ruff.toml tools
actionlint
python3 tools/test_ci_changes.py
python3 tools/test_package.py
python3 tools/test_prepare_release.py
python3 tools/package.py
python3 tools/validate_package.py
```

Format a Lua file with `stylua --config-path .stylua.toml <file>`. `tools/package.py`
builds `build/dist/basic-robots-f2_<version>.zip` and `SHA256SUMS` from tracked release sources;
hidden files, `docs/` and `tools/` never ship. CI attaches the ZIP for seven days.

These checks do not load Factorio. Validate gameplay changes in the game itself; see
[releases](releases.md) for the release process.
