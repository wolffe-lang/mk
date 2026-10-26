Stop. Your code is right: by hand, `gmake -C tests/corpus/recursion` and `./mk -C tests/corpus/recursion` print identical normalized output and both exit 0. You proved that twice. The three red rows are two bugs in test.sh's `same_as_make`, and you can reproduce each with one command.

**Bug 1 — `$PATH` in the rows file is never expanded.** The rows say `--env PATH=/…/v3:$PATH`. `same_as_make` copies that string into `envs` as it is, so the run gets a PATH whose second entry is the four literal characters `$PATH`. gmake is then found by the harness (the parent shell's PATH) but its own sub-make `$(MAKE)` = `gmake` is not. Reproduce (from tests/corpus/recursion):

```
env 'PATH=/Users/mfwolffe/LocalLLM/Projects/mk/mlx-wollf-v7sf3/v3:$PATH' gmake; echo $?     # 127: "env: gmake: No such file or directory"
env 'PATH=/Users/mfwolffe/LocalLLM/Projects/mk/mlx-wollf-v7sf3/v3:$PATH' ../../../mk; echo $?  # 0: mk is in the first entry
```

That is the `levels` row: make exit 127, mk exit 2 (mk's 2 is the comparison's own status after the exit mismatch path; do not chase it).

**Bug 2 — `--env` is consumed only when it is the FIRST argument.** `flags -k -j2 --env … --` and `dry -n --env … --` reach `"$MAKE" "$@"` with `--env PATH=… --` still in `$@`. gmake abbreviates `--env` to `--environment-overrides` and treats `PATH=…:$PATH` as a command-line variable (a literal `$PATH` again → sub-make 127 → exit 2); mk prints its usage and exits 2. Reproduce:

```
gmake -k -j2 --env PATH=x:y -- ; echo $?          # Error 127 inside, exit 2
../../../mk -k -j2 --env PATH=x:y -- ; echo $?    # usage, exit 2
```

**Fix, in `same_as_make` only, nothing else in test.sh:**

1. Consume `--env NAME=value … --` wherever it sits in the arguments, not only first: walk `"$@"` once into two arrays, `envs` (between `--env` and `--`) and `args` (everything else), then use `"${args[@]}"` where `"$@"` was.
2. Expand each env value before use, so `$PATH` means the harness's PATH: `envs+=("$(eval "printf '%s' \"$1\"")")`. (Or, if you prefer no eval: replace a trailing `:$PATH` with `:$PATH`'s value in the loop. One or the other, say which.)

Then `./test.sh | tail -1` → 155 passed. Do not edit the rows, the Makefiles, main.lu or `normalize`. Commit the harness fix on its own ("test.sh: consume --env anywhere and expand its values"), then the recursion work with the message the prompt names. If a row still fails, paste the two normalized outputs side by side before changing anything.
