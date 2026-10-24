# Nudge — the env row fails because its fixture is untracked (P1.1b item 6, 2026-10-24)

Stop. You have run the same grep (`same_as_make"` in test.sh) more than ten times; it will never
match because the function is called without a quote after it. The test is not hiding anything.

**The cause.** `FAIL: env env FOO=bar (make exit 2, mk exit 2)`: both tools exit 2 because neither
found a Makefile. `same_as_make` copies the corpus directory and then runs `clean_copy`
(test.sh:102–110), which deletes every file that `git ls-files` does not list. `tests/corpus/env/`
is untracked (`git status` shows `?? tests/corpus/env/`; `git ls-files tests/corpus/env` prints
nothing), so the copy loses its Makefile and the two tools print two different "no makefile"
errors. Track 01's header says it: "commit a fixture before its row can pass."

Run in the fixture directory to see the real behaviour: `gmake FOO=bar` and `FOO=bar gmake` both
print `bar`, exit 0, and so does `./mk` both ways. mk's environment lookup already works.

**Second problem, fix it at the same time.** The row `env FOO=bar` passes `FOO=bar` as an argument,
which make treats as a command-line override, not as the environment. The judge asked for the
environment (`FOO=bar gmake -f env.mk`). `same_as_make` runs `"$MAKE" "$@"` with no way to set
the environment, so add one: at the top of `same_as_make`, after `shift 2`, consume a leading
`--env NAME=value … --` into an array and run both tools under it:

    local -a envs=()
    if [ "${1:-}" = "--env" ]; then
        shift
        while [ "$1" != "--" ]; do envs+=("$1"); shift; done
        shift
    fi

then change the four invocations of `"$MAKE" "$@"` and `"$ROOT/mk" "$@"` in that function to
`env "${envs[@]}" "$MAKE" "$@"` and `env "${envs[@]}" "$ROOT/mk" "$@"`. The row becomes:

    env --env FOO=bar --

(`env` is the row's name; the first word of a row is always its name.) Existing rows are
unchanged: `v1 A=override` still passes `A=override` as an override.

**Do, in order:** 1. the test.sh change above; 2. the row line; 3. `git add tests/corpus/env test.sh`;
4. `./test.sh | tail -1` → `Results: 104 passed, 0 failed (expected: 104)`; 5. the rest of item 6
(main.lu:23 `"0.2.1"`, CHANGELOG `## Unreleased` with the env line) if not already done;
6. `wolf fmt --check *.lu`; `wolf test .`; 7. commit `CHANGELOG: unreleased; env row`. Stop for the judge.

Found while diagnosing, NOT for now (the judge will list it): without a Makefile, gmake says
`*** No targets specified and no makefile found.  Stop.`; mk says `Makefile: No such file or
directory` then `*** No rule to make target 'Makefile'.  Stop.`
