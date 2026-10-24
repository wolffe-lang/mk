# Track 00 — pickup for P0.2 (a fresh session)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first (WOLF-NOTES, README, SPEC, CHANGELOG, the
standing rules), then read this file, then `00-the-oracle/prompts.md` P0.2 for the goal. **Do not rewrite
`test.sh`.** The previous session stopped at the sentence "it's a complete rewrite, so I'll use write to
replace it entirely". That is the one move the rules forbid. Every step below is an edit of a few lines, and
the reviewer wrote each one against the file as it stands.

## Where things are

Committed and green at HEAD `e35566c` (`wolf build`, `wolf fmt --check *.lu`, `wolf test .` 42, `./test.sh`
94/94): P0.1 is done. The oracle is `gmake` 4.4.1, every message is 4.4.1's, `-C` prints the
`Entering/Leaving directory` lines, and `same_as_make` replaces each tool's copy path with `DIR`.

Uncommitted: twelve files `tests/corpus/<dir>/rows`, one per corpus directory, written by the last session.
`test.sh` does not read them yet. Nothing else is modified (`git status --short` shows only the twelve `??`).

## Step 1 — the rows files, fixed and committed

The helper knows the prefix `again`, not `u1`. In every `rows` file change the line `u1` to `again`
(`sed -i '' 's/^u1$/again/' tests/corpus/*/rows`; check with `grep -c '^again$' tests/corpus/*/rows` → 12
ones). Each file then reads, for example (`missing`):
```
j3 -j 2
again
again-j2 -j 2
d1 -n -j 2
k1 -k
k1b -k
```
Commit: `tests: rows files for the twelve corpus directories`.

## Step 2 — `clean_copy` cleans by the tracked set

A corpus directory's inputs are exactly its git-tracked files (the outputs are git-ignored). Replace the
body of `clean_copy` (the `case "$corpus" in … esac` block, lines 112–125) with:

```bash
    local tracked
    tracked=$(git ls-files "$CORPUS_DIR/$corpus" | sed "s|^$CORPUS_DIR/$corpus/||")
    (cd "$dir" && find . -type f | sed 's|^\./||' | while read -r f; do
        printf '%s\n' "$tracked" | grep -qxF "$f" || rm -f "$f"
    done)
```
Keep the function's first two `local` lines. `./test.sh` must still say 94. Commit: `test.sh: clean_copy
removes what is not tracked`.

## Step 3 — `same_as_make` knows `again`

Change the line
```bash
    if [ "$row" = U1 ] || [ "$row" = U2 ]; then
```
to
```bash
    case "$row" in U1|U2|again*) ;; *) false ;; esac && {
```
and its closing `fi` (the line after the two `(cd … ) || true` lines) to `}`. `./test.sh` still 94. Commit:
`test.sh: a row named again… compares the second run`.

## Step 4 — the rows files feed the matrix

Delete the J3/U1/U2/D1 loop and the K1/S1/V1 lines from the `MATRIX` construction (the `for dir in $STANDARD
fail missing cycle wide; do … done` block and the `MATRIX="$MATRIX` block that follows it with `K1 fail`,
`S1 ignore`, `V1 vars`, `J3 wide -j all`; keep `RJ refuse` and `E1 wide`, which stay function rows). In their
place add:
```bash
for rows in "$CORPUS_DIR"/*/rows; do
    d=$(basename "$(dirname "$rows")")
    while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; esac
        MATRIX="$MATRIX
R $d $line"
    done < "$rows"
done
```
and in the run loop change `J3 | U1 | U2 | D1 | K1 | S1 | V1) same_as_make "$row" "$dir" $args ;;` to
```bash
        R) set -- $args; same_as_make "$1" "$dir" "${@:2}" ;;
```
(the first word of a `rows` line is the row's name, the rest its arguments). `./test.sh` prints lines like
`ok j3 missing -j 2` and ends `Results: 94 passed, 0 failed (expected:       94)`. Add `jall -j all` to
`tests/corpus/wide/rows` if it is not there (it is). Commit: `test.sh: rows files feed the matrix`.

## Step 5 — the plant, the docs, the close

1. Plant: change `k1 -k` to `k1 -kx` in `tests/corpus/missing/rows`; `./test.sh` must print `FAIL: k1
   missing -kx` and exit 1; change it back. Paste both lines.
2. README *Tests*: four lines on `rows` files (one row per line, the first word the name, the rest the
   arguments; a name starting with `again` compares the second run; a copy is cleaned to the directory's
   tracked files; the harness finds every `tests/corpus/*/rows`). CHANGELOG `### Changed`: "rows are files".
   Commit: `README and CHANGELOG: rows files`.
3. Then do P0.3 from `prompts.md` as written (the version, the release commit, the clone proof). Stop for the
   judge.

**Verify, pasted:** `git status --short` empty; the plant's FAIL line and the green `Results` line;
`ls tests/corpus/*/rows | wc -l` (12); `./mk --version`; `git log --oneline | head -10`.
