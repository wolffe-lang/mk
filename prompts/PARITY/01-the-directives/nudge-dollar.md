# Nudge — the `$$` probe (P1.1, 2026-10-24)

Stop. Your last twenty probes measured `/bin/sh`, not `gmake`. There is no gmake bug here, and your
`expand` code for `$$` (expand.lu lines 38–41) is already right. The test is wrong.

**What gmake 4.4.1 does** (paste from the commands below, never from memory):

    X = hello
    E := $$X
    F = $$X
    G := $$(X)
    $(info E=[$(E)] F=[$(F)] G=[$(G)] valueE=[$(value E)] valueF=[$(value F)])
    all:
    	@echo "shell sees E=[$(E)]"
    	@echo 'single quotes E=[$(E)]'

prints

    E=[$X] F=[$X] G=[$(X)] valueE=[$X] valueF=[$$X]
    /bin/sh: X: command not found      <- the shell, running `echo "shell sees E=[$X]"`
    shell sees E=[]
    single quotes E=[$X]

So: `$$` → one literal `$`, and the character after it is plain text, **never re-scanned**. `$$X` is the
two characters `$X`, under `:=` (stored expanded) and under `=` (stored as `$$X`, gives `$X` on every use).
Your recipe probes printed `[]` because make handed `echo "[$X]"` to the shell and the SHELL expanded `$X`
(an empty shell variable). `echo` inside double quotes can never show you a make value that holds `$`.

**How to look at a make value from now on:** `$(info [$(E)])` at parse time, `$(value E)` for the stored
text, or `gmake -pn -f file.mk | grep '^E '` for the database line. Use one of these in every probe whose
answer may contain `$`.

**Fix the test** in `mk_test.lu`, `test_vars_dollar_dollar`, and nothing else:

    set_var(mut v, "E", "$$X", ":=", 1)
    assert((expand(v, "$(E)", 2) else "") == "$X", "dollar dollar immediate")
    set_var(mut v, "F", "$$X", "=", 3)
    assert((expand(v, "$(F)", 4) else "") == "$X", "dollar dollar recursive")

Then run the suite, confirm it is green, and go back to the P1.1b fix list in `judge-P1.1.md` where you
left it. Do not touch expand.lu's `$$` branch.
