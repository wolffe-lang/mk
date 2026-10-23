# mk — ship it (giveaway allowed)

The reviewer cloned the repository, built it, and ran `mk` beside GNU make 3.81 on every corpus directory with
six flag sets, serially and with `-j 2`, first and second run: 240 of 240 runs agree (the 48 others are `-i`,
which mk refuses by name). `wolf test .` 42, `./test.sh` 94, the licence is the official text, `--version` is
right, the usage block equals `--help` byte for byte, and undoing closeout 2a turns the eleven D1 rows red. The
code is ready. What is left is prose, plus one blank line. Edit in place; never rewrite a file.

### SHIP 1 — the format check

`wolf fmt --check main.lu` fails: one blank line is missing after line 22. Run `wolf fmt main.lu`, confirm
`git diff` is that one line, rebuild. Commit: `main.lu: canonical formatting`.

### SHIP 2 — the README

1. The banner, replaced by exactly these four lines (it is the one spell ships; the row count lives below, not here):
   ```
   > **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
   > a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
   > reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
   > script is the reason to trust it.
   ```
2. `Requires wolf (https://wolf-lang.org)` → `Requires wolf 0.2.34 (https://github.com/wolffe-lang/wolf-lang)`. wolf-lang.org does not exist.
3. The opening sentence `… mk builds it identically to GNU make.` → `… mk builds it as GNU make does on
   the corpus below:` (the claim goes only as far as the rows).
4. `Machine: Apple M5 Pro, macOS, wolf 0.1.0.` → `wolf 0.2.34`.
5. `across 10 test kinds` → `across 19 test kinds`.
6. `(output, exit code, or file system state)` → `(output, exit status and the files written)`.
7. The `Files` table gains `README.md` (`this file`) after `CHANGELOG.md`.

Commit: `README: the banner, the wolf link, and the claims the rows prove`.

### SHIP 3 — the CHANGELOG's Fixed lines

- ``Nothing to be done`` (was printed for every up-to-date target)` → `(was missing for a goal with no recipe)`
- `-j without a number sets no limit (was an error)` → `(ran one job at a time)`

Commit: `CHANGELOG: say what the fixes fixed`.

### SHIP 4 — prove it again

```
git add prompts/prompt-ship.md && git commit -m "prompts: the ship prompt"
wolf fmt --check *.lu && ./test.sh | tail -1 && git status --short
rm -rf /tmp/mk-ship && git clone -q . /tmp/mk-ship && cd /tmp/mk-ship && wolf build main.lu -o mk && wolf fmt --check *.lu && wolf test . | tail -1 && ./test.sh | tail -1
```

**Verify:** `wolf fmt --check *.lu` silent; `git status --short` empty; the clone's three result lines;
`git log --oneline | head -5`. Then stop.
