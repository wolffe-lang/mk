# Track 00 — judge (2026-10-23, from a fresh clone at `c61fb21`, 0.2.0)

**Verdict: NOT READY. Three fix prompts (P0.4–P0.6) run before track 01 opens.**

## What holds
- Clean tree; the twelve-commit history the track named; `wolf build` 0, `wolf fmt --check` clean, `wolf test .` 42, `./test.sh` 94/94; the plant (`k1 -kx`) red then green; `mk --version` → `mk 0.2.0 (built with wolf 0.2.34)`; CHANGELOG `## 0.2.0`; README names 4.4.1, has *Known differences*, describes `rows` files.
- The reviewer's own matrix against `gmake` 4.4.1: 12 directories × {∅, -s, -k, -n, -s -k, -C .} × {serial, -j 2} × {run 1, run 2} = **288/288 agree** (output with the copy path as `DIR`, exit status, files written). The four usage errors agree on the first line.
- The parser change is sound: a `Line { text, line }` record through `join_continuations`, `recipe_lines` on `Rule`.

## What does not (found by probes outside the corpus)
1. **The line in `[Makefile:N: target]` on a continued recipe.** gmake's N is *the physical line of the rule's first recipe line + the index of the failing logical recipe line*, ignoring continuation and blank lines: recipe at lines 2–4 (one logical line), 5, 6–7 → the third fails as `Makefile:4`; recipe at 3 and 5 with a blank between → the second fails as `Makefile:4`. mk reports the physical line (6, 5).
2. **A continuation line inside a recipe keeps its leading tab.** gmake removes exactly one leading tab from each continued recipe line and keeps the backslash-newline: `\tprintf … x \` / `\t\t  y \` / `\tz` is echoed and run as `printf … x \`, `\t  y \`, `z`. mk echoes `\t\t  y \` and `\tz`.
3. **`Leaving directory` is skipped on every exit before the build** (a refusal, a missing `-f` file, a parse error): `main.lu` prints it only at line 463. Found with it: a line that is neither rule, assignment nor recipe (`foo bar`) is silently ignored where gmake stops with `Makefile:2: *** missing separator.  Stop.`; and `-f nope` prints `mk: cannot read nope` where gmake prints `gmake: nope: No such file or directory` then `gmake: *** No rule to make target 'nope'.  Stop.`

None of these is in the 94 rows; P0.4–P0.6 add the rows first.

## Second judge (2026-10-24, from a fresh clone at `5942bdd`, 0.2.1)

**Verdict: READY. Track 00 is closed; track 01 is open.**

- Clean tree; `wolf build` 0; `wolf fmt --check *.lu` clean; `wolf test .` 42; `./test.sh` **100/100** (94 + the six rows P0.4–P0.6 added); `mk --version` → `mk 0.2.1 (built with wolf 0.2.34)`.
- The three defects, probed again outside the corpus against `gmake` 4.4.1, each with the copy path as `DIR` and the program name the only difference:
  1. continued recipe (`x \` / `\t\t  y \` / `\tz` then `@false`): both print `x 	  y z` and `*** [Makefile:3: all] Error 1`, exit 2;
  2. a recipe with blank lines before the failing line: both say `[Makefile:5: all]`;
  3. `foo bar` as the first line: both `Makefile:1: *** missing separator.  Stop.`, exit 2; `-C . -f nope`: both print `Entering` and `Leaving` around the two `nope` lines; `-C . -k -n`: both print the three lines.
