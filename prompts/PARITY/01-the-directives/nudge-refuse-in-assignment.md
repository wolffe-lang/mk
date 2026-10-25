# Nudge — the `:=` assignment swallows the refusal; and the functions rows are R1/RJ rows (P1.9, 2026-10-25)

Stop. Your diagnosis was right and the session ended before the fix: `set_var_impl`'s `:=` branch
(vars.lu:91–95) catches every `expand` error and stores the raw text —

```
let expanded = expand(v, value, line) else |e| match e {
    Unterminated(l) => value,
    Cycle(l, n) => value,
    Refuse(l, msg) => value,
}
```

— so `Y := $(subst a,b,abc)` stores `$(subst a,b,abc)` as an immediate value, and `@echo $(Y)` later
hands it to the shell untouched. The refusal must leave `set_var`. Do not make every `set_var` fallible;
the parser already has the channel: `db.refusals` (parse.lu:1036 pushes `Refusal { kind, line }` for an
unsupported assignment name). Three edits, then the rows.

**1. vars.lu — one new function, the old one unchanged for its other callers (about 15 lines).**
Add, beside `set_var`:

```
/// Set a Makefile assignment; a refused construct in an immediate value is the caller's to report.
fn set_var_checked(mut v: Vars, name: str, value: str, flavour: str, line: int) -> () ! {Refuse(int, str)} {
    if flavour == ":=" {
        let expanded = expand(v, value, line) else |e| match e {
            Unterminated(l) => value,
            Cycle(l, n) => value,
            Refuse(l, msg) => return Refuse(l, msg),
        }
        set_var(mut v, name, expanded, "=immediate", line)   // see 2
        return
    }
    set_var(mut v, name, value, flavour, line)
}
```

**2. vars.lu — `set_var_impl` must not expand a second time.** Give the `:=` branch a way to store an
already-expanded value: accept the flavour spelling `"=immediate"` in `set_var_impl` as "store `value`
as is with flavour `:=`" (two lines: `} else if flavour == "=immediate" { map.set(... flavour: ":=" ...) }`
before the `:=` branch). `override define` (parse.lu:872) already passes an expanded value with op `:=`
and is expanded twice today; switch it to `"=immediate"` too.

**3. parse.lu — the three Makefile assignment sites use the checked call.** Lines 991, 1043 and 1192
(`set_var(mut v, <name>, <value>, <op>, <line>)` for an assignment read from the Makefile) become:

```
set_var_checked(mut v, assignment.name, assignment.value, assignment.op, assignment.line) else |e| match e {
    Refuse(l, msg) => {
        (mut db.refusals).push(Refusal { kind: msg, line: l })
        line_num += 1
        continue
    },
}
```

(at 991 and 1192 use that site's own variable names and loop step). `MAKEFILE_LIST` (1210/1212) and the
environment copy (1238) keep plain `set_var`: nothing in them can be refused. The `+=` onto an existing
`:=` variable (vars.lu:71) has the same swallow; leave it for this pass and name it in the CHANGELOG
("`+=` to an immediate variable still stores a refused function's text; P1.10").

**4. The rows — there is no `# expect:` mechanism; the prompt misnamed it.** `refuse/pattern.mk` is
tested by **R1** (exit 2, empty stdout, exactly one stderr line, and the stderr line contains the file's
basename) and **RJ** (the same answer under `-j 2`). The three files you wrote are right; the `rows` file
is wrong: a `rows` line becomes a matrix row `R functions RJ functions`. Delete
`tests/corpus/functions/rows`. In `test.sh`, add `functions` beside `refuse` in the three places that name
it: the directory list (line 39), `R1 refuse` and `RJ refuse` in the matrix (lines 76 and 87), and raise
the expected count by 2. The stderr lines already contain the basenames (`…/functions/assign.mk:2: …`).

**Verify, in this order:** `wolf build main.lu -o mk`; `./mk -f tests/corpus/functions/assign.mk; echo $?`
→ `mk: tests/corpus/functions/assign.mk:2: functions are not supported` and `2`, nothing on stdout; the same
for `recipe.mk` (line 3) and `info.mk` (line 2); `wolf test .`; `./test.sh | tail -1` → `Results: 119
passed, 0 failed (expected: 119)`. Commit as "Refuse functions in immediate assignments; functions rows",
then continue P1.9's items 2 and 3. Do not rewrite any file; every edit above is under 20 lines.
