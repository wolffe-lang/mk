# mk — closeout 8 of 8: the README says only what the binary does, and a clone proves it (giveaway allowed)

Edit `README.md` in place, a section at a time; never rewrite it whole.

### CLOSE 8a — the README (RELEASE 10)

1. **The usage block** is the whole of `./mk --help`, pasted byte for byte. That includes closeout 7's `-j [N]` line; the block today starts `mk [-f FILE]` and is not the binary's.
2. **The "No rule to make target" example** is the binary's own line, with its backtick quotes. Paste it from `cd tests/corpus/missing && ../../../mk`:
   ``mk: *** No rule to make target `missing_file', needed by `result'.  Stop.``
3. **"`mk` builds it identically to GNU make"** stays only as far as the rows prove it. Replace it with one sentence naming what `test.sh` compares against GNU make 3.81:
   - on 12 corpus directories: the first and the second run, serially and with `-j 2`, and `-n -j 2`;
   - on their own directories: `-k`, `-s` and a command-line variable;
   - each comparing the output, the exit status and the files written.

   Then say the refusals and usage errors are checked by name.
4. **The `Files` table** lists exactly `git ls-files` at the top level, plus `prompts/` and `tests/corpus/`. `REVIEW.md` is gone.
5. **The tests section** gives today's counts: `wolf test .` 42 and `./test.sh` 94 rows.
6. **`prompts/`** holds `prompt.md`, `prompt-followup.md`, `prompt-resume.md`, `prompt-final.md`, `prompt-release.md` and `prompt-close1.md` … `prompt-close8.md`. Say so in one line.

Then add a `### Fixed` part to the `0.1.0` entry in `CHANGELOG.md`, one line each:
- `-k -j` exit status;
- command-line variables while parsing;
- ``Nothing to be done``;
- `-s` and `-k` messages, serial and `-j`;
- `-n -j` runs nothing;
- usage errors name the problem;
- `-j` without a number sets no limit;
- the official licence;
- `--version`.

Commit the two files together: `README and CHANGELOG say what the binary does`.

### CLOSE 8b — prompts, then prove it from a clone

```
git add prompts/
git commit -m "prompts: the prompts that built mk"
./test.sh && git status --short          # nothing may follow the Results line
rm -rf /tmp/mk-fresh && git clone -q . /tmp/mk-fresh && cd /tmp/mk-fresh && wolf build main.lu -o mk && wolf test . && ./test.sh
```

**Verify:**
- `git status --short` is empty in this directory;
- the clone's `wolf test .` line and `Results: 94 passed, 0 failed` line;
- `awk '/^Usage: mk/{p=1} p&&/^```/{exit} p' README.md | diff - <(./mk --help)` is empty;
- `git log --oneline | head -14`.

Then stop.
