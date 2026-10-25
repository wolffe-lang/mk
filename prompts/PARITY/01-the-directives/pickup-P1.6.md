# Track 01 — pickup for P1.6 (a fresh session, 2026-10-24)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first: `cp ../../../WOLF-NOTES.md .` and read it,
then README, SPEC, CHANGELOG, the campaign's *Standing rules*, `00-the-oracle/judge.md`, this track's
`prompts.md` from the top and `judge-P1.1.md`. Then read this file to the end before touching anything.
**Do not rewrite any file. Do not write probe programs under /tmp. Do not run `wolf build mk_test.lu`** —
`wolf build main.lu -o mk` builds the whole directory as one module, and `wolf test .` runs the unit tests.

## Where the track stands

Committed and green at HEAD `ed2ede6`: P1.1–P1.5 are done. The expander is real (`expand.lu`), the reader
is one-pass, `include`/`-include`/`sinclude` and `-I DIR`, the conditionals, `define`/`endef`/`undefine` and
`override define` all land; recipe lines split on bare newlines and keep backslash-newline continuations
(`split_recipe_lines`, run.lu:51). At HEAD: `wolf test .` 50 passed; `./test.sh | tail -1` → `Results: 117
passed, 0 failed (expected: 117)`. Only pattern rules, `.SUFFIXES`, order-only, double-colon and functions
are still refused by name.

**Uncommitted in the tree, from the last session (P1.6, about 230 lines):**
- `main.lu`: the `-e` flag (`env_wins` in `Flags`, the usage line, `parse_arg`/`parse_flags`), passed to
  `parse_makefile_file`; a call to `export_environment(v)` after parsing and before `build_graph`.
- `vars.lu`: `Var.exported`, `Vars.export_all`, `Vars.unexported`, `set_var_exported`, `var_exported`, and
  `export_environment(v: Vars) -> () ! {invalid}` — the function `nudge-export-env.md` asked for (read that
  nudge: it explains why there is no per-command environment and pastes the gmake witnesses).
- `parse.lu`: `override define` / `override undefine` (lines ~801–835), `export NAME`, `export NAME op v`,
  bare `export` (~837–905), `unexport NAME` and bare `unexport` (~906–930).
- `mk_test.lu`: one line.

**It does not build.** `wolf build main.lu -o mk` says
`cannot compile this yet — open-ended or end-relative ranges (slicing) @28771..28778`. The bytes are
parse.lu:891. That message misnames the cause (wolf-lang#932): in
`rest[rest.find(":=") else 0 + 2..]` the `else` fallback swallows everything after it, so the fallback reads
as `0 + 2..`, an open-ended range *value*. Open-ended slices themselves are fine (`s[p..]` runs). Nothing is
to be moved to another file.

## Step 0 — the build, four lines

In parse.lu, inside the `export` block (`if op.len > 0 {`), replace the four slices at lines 891, 893, 895
and 897 so each binds its position first:

```
                let value = if op == ":=" {
                    let p = (rest.find(":=") else 0) + 2
                    rest[p..]
                } else if op == "+=" {
                    let p = (rest.find("+=") else 0) + 2
                    rest[p..]
                } else if op == "?=" {
                    let p = (rest.find("?=") else 0) + 2
                    rest[p..]
                } else {
                    let p = (rest.find("=") else 0) + 1
                    rest[p..]
                }
```

Then `wolf build main.lu -o mk` prints nothing and exits 0. If it names a second refusal, apply the same
rule (`campaign.md` "When wolf says cannot compile this yet": find the bytes, never guess the file) and go
on. `wolf fmt --check *.lu`; `wolf test .` (50 or more, all passed); `./test.sh | tail -1` → still 117.

## Step 1 — the rows, committed red

`tests/corpus/export/` with these files (expected answers measured on gmake 4.4.1, 2026-10-24):

- `Makefile`:
  ```
  X = 1
  export Y = 2
  Z = 3
  all:
  	@echo [$$X-$(X)][$$Y][$$Z]
  ```
  (a tab before `@echo`). `gmake` → `[-1][2][]`; `X=env gmake` → `[1-1][2][]`; `X=env gmake -e` → `[env-env][2][]`.
- `all.mk`: `export` on its own line, then `A = 1`, `all:`, `<tab>@echo [$$A]` → `[1]`.
- `un.mk`: `unexport HOME`, `all:`, `<tab>@echo [$$HOME]` → `[]`.
- `ov.mk`: `A = 1`, `override A = 2`, `all:`, `<tab>@echo [$(A)]`; run with `A=cli` → `[2]`.
- `rows`:
  ```
  plain
  envx --env X=env --
  e --env X=env -- -e
  all -f all.mk
  un -f un.mk
  ov -f ov.mk A=cli
  ```
  (`--env NAME=VALUE --` is the environment form `same_as_make` already understands, test.sh:467.)

`git add tests/corpus/export`; `./test.sh | tail -1` → `(expected: 123)` with reds; commit
`rows: override, export, unexport, -e (red)`.

## Step 2 — green, README, CHANGELOG, commit

Make the six rows green with the code already in the tree: `export_environment` must set exactly the
variables GNU exports (environment-origin ones with their current value, `export`ed ones, everything under
bare `export`; an `unexport`ed name removed with `env_unset`); `-e` makes an environment value win at
assignment time; `override` skips the command-line check. `wolf build main.lu -o mk && wolf fmt --check
*.lu && wolf test . && ./test.sh | tail -1` → `Results: 123 passed, 0 failed (expected: 123)`.

README: re-paste the usage block from `./mk --help` (it gained `-e`); *Accepted* gains `export NAME` /
`export NAME = v` / `export` / `unexport`, `override NAME = v`, `-e`, each with its one-line example;
`.EXPORT_ALL_VARIABLES:` as a target means bare `export` — implement and list it, or list it under *Known
differences* if you leave it. CHANGELOG `## Unreleased` `### Added`: the four directives and `-e`.

The edits interleave, so commit everything now modified as one batch (campaign rule 5):
`override, export, unexport, -e`. Then **stop** and paste: the six `ok` row lines, `./test.sh | tail -1`,
`git log --oneline | head -5`.

## After the judge: P1.7

P1.7 in `prompts.md` is the track's last prompt (the variables make sets — `MAKE` as the literal `mk`
until the pin has `argv[0]`, `CURDIR`, `MAKEFLAGS`, `MAKELEVEL`, `.DEFAULT_GOAL` — and `Release 0.3.0`).
Do not start it in this session.

## Earlier nudges, for the record (already applied, do not redo)

`nudge-dollar.md` (P1.1b: `$$` probes measured the shell), `nudge-version.md` (`VERSION` is a constant in
main.lu), `nudge-env-row.md` (an untracked fixture cannot pass; the `--env … --` form), `nudge-define-split.md`
(recipe lines split on bare newlines), `nudge-export-env.md` (children inherit `env_set`'s environment).
