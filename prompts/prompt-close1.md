# mk — closeout 1 of 8: commit what is done (giveaway allowed)

You are finishing **mk**, a `make` for the plain Makefile subset, written in wolf, in this directory.
- **Build:** `wolf build main.lu -o mk`.
- **Tests:** `wolf test .` (42 tests) and `./test.sh`, which runs rows against GNU make 3.81 at `/usr/bin/make`.

This prompt is the first of eight closeout prompts, given one at a time. Each one ends in commits and then you stop.

**Two rules for every closeout prompt:**
- Never rewrite a whole file. Edit in place, at most about 60 lines per edit. The last session hung while writing a new `test.sh` in one go.
- After every code change, rebuild `mk` before running `./test.sh`.

**Where things stand.** The reviewer copied the working tree, built it, and ran `mk` beside GNU make on every corpus directory from clean, serially and with `-j 2`, twice each. **48 of 48 runs agree.** Of the release round:
- RELEASE 1 (`-k -j 2` exit status), 2 (`A=override` while parsing) and 3 (`Nothing to be done`) are done and correct.
- RELEASE 4 (`-s` and an ignored error) and 5 (`-k` and a missing prerequisite) are right serially but not with `-j 2`; closeout 2 fixes that.
- RELEASE 6–10 were never reached.
- None of it is committed.

Commit what is done now, in three commits, exactly:

```
git commit -m "Remove REVIEW.md and the cycle and linear outputs" -- REVIEW.md tests/corpus/cycle/b tests/corpus/linear/a tests/corpus/linear/b tests/corpus/linear/c
git add graph.lu main.lu run.lu vars.lu
git commit -m "Fix -k -j exit status, command-line variables while parsing, and the up-to-date and -s/-k messages"
git add test.sh
git commit -m "test.sh: J3 compares mk -j 2 with make -j 2"
```

Do not stage `LICENSE`, `README.md`, `.gitignore`, the deleted corpus outputs or `prompts/` yet. Later closeouts commit them.

**Verify:**
- `git log --oneline | head -4`;
- `git status --short | grep -v '^ D tests/corpus/'` shows exactly ` M .gitignore`, ` M LICENSE`, ` M README.md` and `?? prompts/`;
- `wolf build main.lu -o mk`, `wolf test .` and `./test.sh` are green (50 rows).

Then stop.
