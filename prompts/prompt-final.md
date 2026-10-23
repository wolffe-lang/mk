# mk — the final round before publishing (giveaway allowed)

The reviewer built a fresh clone and ran `mk -j 2` beside `make -j 2` on every corpus directory, using
`test.sh`'s own copy-and-clean routine. Seven of thirteen agree. Three do not, and the release files need
fixing. One commit per item, then stop and paste the last lines.

### FINAL 1 — The parallel path loses three things the serial path has

| corpus | `make -j 2` | `mk -j 2` |
|---|---|---|
| `cycle` | `make: Circular b <- a dependency dropped.`, `` `a' is up to date. ``, exit 0 | `mk: *** internal error: 2 target(s) never became ready`, exit 2 |
| `missing` | ``make: *** No rule to make target `missing_file', needed by `result'.  Stop.``, exit 2 | the internal error, exit 2 |
| `wide` (second run) | ``make: Nothing to be done for `all'.`` | nothing |

The serial path gets all three right, so the parallel path must make the same decisions at the same
moments. (1) When `discover_targets` meets a prerequisite already on the current DFS path, print the serial
path's circular-dependency line and record the edge as dropped (the serial path's `built` value -1); then
`prereqs_done` treats a dropped edge as done. (2) A prerequisite with no rule and no file prints the serial
path's "No rule to make target" line (with `needed by`) and stops, exit 2, before anything else is
launched. (3) A goal found up to date with nothing rebuilt beneath it prints the serial path's message.
After these, the internal-error guard should be unreachable on every corpus directory.

### FINAL 2 — A `-j` row for every directory

`test.sh`'s J1 and J2 cover `wide` and `diamond` only, which is why FINAL 1 shipped. Add a row per corpus
directory: `mk -j 2` and `make -j 2` in fresh copies, the same sorted output (with `make:` read as `mk:`)
and the same exit status. Plant: undo FINAL 1 (1) and show `cycle`'s row red, then green.

### FINAL 3 — `--version`

`mk --version` exits 2 and prints nothing. Print `mk 0.1.0 (built with wolf 0.2.34)`, from one constant,
exit 0, and list it in `--help`.

### FINAL 4 — The README, the licence and the tree

- The top of the README is this banner, verbatim (it replaces the honesty line):

  > **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
  > a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
  > reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
  > script is the reason to trust it.

- wolf's address is https://github.com/wolffe-lang/wolf-lang (`wolf-lang.org` is not it). The measured
  numbers name `wolf 0.2.34`, not `wolf 0.1.0`. The usage block is byte-identical to `./mk --help`.
- The licence is Apache-2.0 (the maintainer's ruling for both wollf-built tools): replace the MIT `LICENSE`
  with the Apache License 2.0 text, and do not write that it is the licence wolffe-lang's tools use.
- A `.gitignore` for `mk`, `mk.dSYM`, `mk_test`, `mk_test.dSYM`, `.lu-cache/`. The built outputs under
  `tests/corpus/` (`a`, `b`, `c`, `out1.txt`, `result`, …) are made by the tests and stop being tracked
  (`git rm --cached`, and ignored); the tests already remove them before each run.
- `prompts/` is part of the repository: `prompt.md`, `prompt-followup.md`, `prompt-resume.md` and this
  file. `JUDGE.md` stays out.

**Verify:** `wolf build main.lu -o mk` exit 0; `wolf fmt --check *.lu`; `wolf test .` and `./test.sh` green
with the new rows; the plant red then green; `mk -j 2` equal to `make -j 2` on all thirteen directories; a
fresh clone into an empty directory builds and passes; the README's examples and usage equal the binary's
output; `git ls-files` matches the README's file list.
