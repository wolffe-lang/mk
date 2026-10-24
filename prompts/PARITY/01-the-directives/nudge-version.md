# Nudge — where `VERSION` lives (P1.1b item 6, 2026-10-24)

Stop. You have run the same grep (`version"` in main.lu) eleven times and read the same four lines
each time. Nothing was removed in the churn. `VERSION` is not a file: it is a constant in `main.lu`,
and campaign rule 7 says so ("bumps `VERSION` in `main.lu`"). Your first grep missed it because the
value has three components: `0\.2"` cannot match `"0.2.2"`.

    main.lu:22:/// The version string, embedded at build time.
    main.lu:23:let VERSION: str = "0.2.2"
    main.lu:25:let WOLF_VERSION: str = "0.2.34"

(`./mk --version` prints `mk 0.2.2 (built with wolf 0.2.34)` from lines 431 and 459.)

Item 6, done in this order and nothing else:

1. `main.lu` line 23: `"0.2.2"` → `"0.2.1"`.
2. `CHANGELOG.md`: the heading `## 0.2.2 (2026-10-24)` → `## Unreleased`. Keep every bullet under it.
   Add one line under its `### Added`: environment variables are looked up when a Makefile variable
   is undefined (`FOO=bar mk` sees `$(FOO)`).
3. The env row: a new corpus directory with a Makefile `all:` / `@echo $(FOO)` and a `rows` line that
   runs it with `FOO=bar` in the environment; expected output `bar` (gmake 4.4.1 prints `bar`;
   paste it from your own run, never from memory). Commit the fixture before running the row.
4. `wolf fmt --check *.lu`; `wolf test .`; `./test.sh | tail -1` (expect 104 = 102 + self + env).
5. `git add -A && git commit -m "CHANGELOG: unreleased; env row"`.

Verify as the fix list says: `./mk --version` → `mk 0.2.1 (built with wolf 0.2.34)`, `git status --short`
empty, `git log --oneline -7`. Then stop for the judge.

Rule for the future: when a grep for something you know exists returns the same result twice, change
the search (a wider pattern, `-i`, the whole directory), never repeat it.
