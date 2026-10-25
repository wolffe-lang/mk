# Nudge — define bodies and recipe continuations both use `\n`; split on the right one (P1.5, 2026-10-24)

Stop. You have written the sentence "this is a significant change to the recipe processor" more than
twenty times and flipped `run.lu` between `final_line.lines()` and no split four times. Neither is the
answer, and no refactor is needed. The fix is one small function.

**The cause.** `join_continuations` (parse.lu:92) stores a recipe continuation with the
backslash-newline *kept inside the text*: `@echo "one \` + `\n` + `two"` is one recipe line, and
`recipe_for_shell` (run.lu:53) hands that pair to `/bin/sh`, which treats it as a continuation. A
`define` body is stored with *bare* newlines between its lines. Both reach `build_target` as one
expanded string, so:

- `final_line.lines()` splits on every `\n` and cuts the recipe continuation in two
  (`continuation`, `recipes build`, `recipes -k` fail: `unexpected EOF while looking for matching '"'`);
- no split runs `@echo line1\n@echo line2` as one shell line (`define` fails: `@echo: command not found`).

The rule that satisfies both is gmake's own: **a newline ends a recipe line unless a backslash
precedes it.** Measured with gmake 4.4.1, `all: ; @echo start; $(two)` where `two` is a two-line
define prints `start`, then `/bin/sh: @echo: command not found`, exit 2 — the bare newline from the
define splits the line; a backslash-newline never does.

**The fix, in `run.lu`.** Add this function beside `recipe_for_shell`:

```
/// Split an expanded recipe line into the lines the shell runs one by one.
/// A newline ends a line unless a backslash precedes it: that pair is a
/// continuation the shell sees (recipe_for_shell), so it stays inside the
/// line. A define body's bare newlines become separate recipe lines.
fn split_recipe_lines(s: str) -> List[str] {
    var result = List[str]()
    var start = 0
    var i = 0
    while i < s.len {
        if s[i..i + 1] == "\n" && (i == 0 || s[i - 1..i] != "\\") {
            (mut result).push(s[start..i])
            start = i + 1
        }
        i += 1
    }
    (mut result).push(s[start..])
    return result
}
```

Then change run.lu:120 from `let lines = final_line.lines()` to `let lines = split_recipe_lines(final_line)`.
Keep the loop you already wrote (each resulting line takes its own `@` and `-`; an empty line runs no
shell). Nothing else in `build_target` changes. Add a unit test in `mk_test.lu`:
`split_recipe_lines("a \\\nb\nc")` → three? No — two: `["a \\\nb", "c"]`; and `("x\n\ny")` → `["x", "", "y"]`.

**Then, in order:**
1. `wolf build main.lu -o mk`; `./test.sh | tail -1` → `Results: 116 passed, 0 failed (expected: 116)`.
2. `rm a.txt b.txt c.txt` in the repository root (outputs of running the `continuation` fixture from the
   root with `-f`; they are `??` in `git status` and belong to no commit).
3. `wolf fmt --check *.lu`; `wolf test .`.
4. Commit everything now modified as one batch (campaign rule 5): `define and endef; recipe lines split
   on bare newlines` — the message lists parse.lu's define stack, run.lu's split, the refusal deleted,
   `tests/corpus/refuse/define.mk` removed, the define rows.
5. P1.5's remainder: `undefine NAME` (the variable is removed; `ifdef` then false) and `override define`
   / `override undefine` (for now `override` is accepted and the name after it handled as if absent;
   P1.6 gives it its meaning). Witness, pasted from gmake 4.4.1 on
   `A = x` / `undefine A` / `ifdef A` / `$(error still)` / `endif` / `override define B` / `b1` /
   `endef` / `all:` / `<tab>@echo [$(A)][$(B)]`, run as `gmake -f M3 B=cli`: prints `[][b1]`, exit 0.
   Add that Makefile as `tests/corpus/define/undef.mk` with a row `undef -f undef.mk`; the expected
   count becomes 117. Commit `undefine, override define`.
6. README: move `define` / `endef` from *Refused* to *Accepted* (add `undefine`); CHANGELOG `### Added`.
   Commit. Stop for the judge.

**Found while diagnosing, NOT for now (the judge will list it):** gmake keeps a define body verbatim —
a body line `# not a comment?` is a recipe line (printed, then a shell comment) — while
`join_continuations` strips `#` from every non-recipe logical line, so mk drops it. Backslash-newline
inside a body gmake joins with one space at definition (`-p` shows `@echo two three`), which mk already
does. A tab-prefixed body line keeps its tab in both.
