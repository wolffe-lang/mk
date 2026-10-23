# mk — closeout 6 of 8: the tree ships only inputs, the licence, the version (giveaway allowed)

Three small items, one commit each, in this order.

### CLOSE 6a — the tree ships only inputs (RELEASE 8)

56 files the corpus Makefiles write are still tracked, among them `vars/vars.out`, which holds the builder's home directory. `.gitignore` names files that do not exist (`wide/a` … `g`, `diamond/a` … `d`, …) and misses the real ones. Run exactly:

```
git rm -q --cached tests/corpus/auto/a tests/corpus/auto/b tests/corpus/auto/c tests/corpus/auto/d \
  tests/corpus/continuation/a.txt tests/corpus/continuation/b.txt tests/corpus/continuation/c.txt \
  tests/corpus/diamond/base tests/corpus/diamond/left tests/corpus/diamond/right \
  tests/corpus/fail/other tests/corpus/ignore/result tests/corpus/leaf/out1.txt tests/corpus/leaf/out2.txt \
  tests/corpus/phony/prog tests/corpus/vars/vars.out
git rm -q --cached 'tests/corpus/wide/t[0-9][0-9]'
```

Then replace `.gitignore`'s whole content with exactly this (a small file, so one write is fine):

```
# Build artifacts
mk
mk.dSYM/
mk_test
mk_test.dSYM/
.lu-cache/

# What the corpus Makefiles write. test.sh works in temporary copies, so these
# appear only when mk or make is run inside tests/corpus by hand.
tests/corpus/auto/a
tests/corpus/auto/b
tests/corpus/auto/c
tests/corpus/auto/d
tests/corpus/continuation/a.txt
tests/corpus/continuation/b.txt
tests/corpus/continuation/c.txt
tests/corpus/cycle/a
tests/corpus/cycle/b
tests/corpus/diamond/base
tests/corpus/diamond/left
tests/corpus/diamond/right
tests/corpus/fail/other
tests/corpus/fail/result
tests/corpus/ignore/result
tests/corpus/leaf/out1.txt
tests/corpus/leaf/out2.txt
tests/corpus/linear/a
tests/corpus/linear/b
tests/corpus/linear/c
tests/corpus/missing/result
tests/corpus/phony/prog
tests/corpus/vars/vars.out
tests/corpus/wide/t[0-9][0-9]
```

`git add .gitignore`, then commit: `Track only the corpus inputs; ignore what the Makefiles write`.

**Check:** `git ls-files tests/corpus` lists only Makefiles, `refuse/*.mk`, `leaf/src1.txt`, `leaf/src2.txt`, `leaf/shared.txt` and `vars/golden-p.txt` (24 files).

### CLOSE 6b — the licence is the official text (RELEASE 7)

`LICENSE` is a retyping (190 lines; §1, §3 and §4 differ from the Apache License 2.0, and the APPENDIX is gone). A licence is never typed from memory:

```
curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o LICENSE
shasum -a 256 LICENSE   # must print cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30
```

`git add LICENSE`, then commit: `LICENSE: the official Apache License 2.0 text`.

### CLOSE 6c — `--version` (RELEASE 9)

`mk --version` prints `mk 0.1.0`. It must print `mk 0.1.0 (built with wolf 0.2.34)` and exit 0. Both parts come from constants in one place in `main.lu`, next to `let VERSION: str = "0.1.0"`: add `let WOLF_VERSION: str = "0.2.34"` and print both. Rebuild. Commit: `--version names the wolf it was built with`.

**Verify:**
- `git ls-files tests/corpus | wc -l` prints 24;
- `shasum -a 256 LICENSE` as above;
- `./mk --version`, then `echo $?`;
- `./test.sh` green at 92, and then `git status --short` shows only `?? prompts/` and ` M README.md`;
- `git log --oneline | head -4`.

Then stop.
