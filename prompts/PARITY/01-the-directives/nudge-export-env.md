# Nudge — a child inherits the environment; there is no per-command environment to find (P1.6, 2026-10-24)

Stop. You have written twelve probe programs guessing names (`process.env`, `process.env_set`,
`process.env_push`, …) and said "let me check the wolf documentation" eleven times without the file
being there: `WOLF-NOTES.md` is not in this directory (it is copied in by campaign.md's "Start of every
session"; `cp ../../../WOLF-NOTES.md .` brings it back — the gitignore keeps it out of commits). None of
those names exist and no reading will produce one. `std.process`'s `Command` has `command`, `push_arg`,
`run`, `start`, `poll`, `kill` — and **no environment**, by design.

**The mechanism.** A wolf child receives its parent's environment, the way every unix child does. The
builtins `env_set(name, value) -> () ! {invalid}` and `env_unset(name) -> () ! {invalid}` (no import)
change *mk's own* environment, and every child started afterwards sees the change. Verified on this
toolchain (wolf 0.2.34): a program that calls `env_set("FOO", "bar")`, `env_unset("HOME")` and then runs
`/bin/sh -c 'echo [$FOO][$HOME]'` through `process.run` prints `[bar][]`. That is the whole API you need.
GNU make does the same thing: it builds the child's environment from its variable table.

**The design, in one function.** Variables are final once the Makefile is read (P1.2: one pass), so the
environment is prepared **once**, after parsing and before the first target is built — not per spawn.
In `vars.lu` (or `main.lu`), write:

```
/// Give recipes the environment GNU make gives them: variables that came
/// from the environment (their current value), the exported ones, and
/// everything when `export` stands alone; an unexported name is removed.
fn export_environment(v: Vars) -> () ! {invalid}
```

For each variable in the table, in definition order: if it is unexported by name (`unexport NAME`) →
`env_unset(name)`; else if `export` alone was seen, or the variable is marked exported, or its origin is
the environment → `env_set(name, value)` where `value` is the variable's expanded value (recursive ones
expand now; `$$` stays `$`). Nothing else changes in `run.lu`: both `process.run` and `process.start`
inherit the result. Call it in `main.lu` right after `parse_makefile` returns, before `build_*`;
`invalid` (a name holding `=` or NUL) is a Makefile error — print GNU's line for it if you can paste one,
otherwise `mk: *** invalid variable name '{name}'.  Stop.` exit 2 and say so in the README.

What the table needs for this (small additions to the variable record and the parser): a `exported: bool`
per variable, set by `export NAME` and `export NAME = v` (which also assigns), cleared by `unexport NAME`
(record the unexport so `env_unset` runs even for environment-origin names); a module-level flag for
bare `export` / `.EXPORT_ALL_VARIABLES:` as a target; `unexport` alone clears the flag and every mark.
`override NAME = v` is the assignment with the command-line check skipped.

**Witnesses, measured on gmake 4.4.1 today** (Makefile `X = 1`, `export Y = 2`, `Z = 3`, recipe
`@echo [$$X-$(X)][$$Y][$$Z]`):
- `X=env gmake` → `[1-1][2][]` — an environment-origin variable is exported with the Makefile's value;
  an unexported Makefile variable is absent from the shell.
- `X=env gmake -e` → `[env-env][2][]` — `-e` makes the environment win at assignment time.
- `gmake` (no X) → `[-1][2][]`.
- `export` alone then `A = 1`, recipe `@echo [$$A]` → `[1]`.
- `unexport HOME`, recipe `@echo [$$HOME]` → `[]`.
- `A = 1` then `override A = 2`, run `gmake A=cli` → `[2]`.

**Do, in order:** 1. `cp ../../../WOLF-NOTES.md .`; 2. `rm /tmp/test_proc*.lu /tmp/test_proc*` (your
probes); 3. the table marks and the four directives in `parse.lu` (`export`, `unexport`, `override`,
`.EXPORT_ALL_VARIABLES`), `-e` in `main.lu` (environment wins in `set_var` when set); 4.
`export_environment` and its call; 5. rows per P1.6 (`export/` with `plain`, and `e -e` using the
`# env:` line the prompt describes for `same_as_make`); 6. `wolf build main.lu -o mk`; `./test.sh | tail -1`;
`wolf fmt --check *.lu`; `wolf test .`; 7. commit as one batch if the edits interleave (rule 5):
`override, export, unexport, -e`; README (usage block re-pasted, *Accepted* rows), CHANGELOG. Stop for
the judge.

Not for now: the environment mk hands a child also carries whatever mk itself received; GNU additionally
exports `MAKEFLAGS`, `MFLAGS` and `MAKELEVEL` — those are P1.7's.
