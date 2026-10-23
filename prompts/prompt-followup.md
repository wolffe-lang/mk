# mk — follow-ups after v3 (low give-away)

Paste these one at a time into the same session (or a fresh one in this directory). Each names what a
reviewer saw, the bar, and the questions to think through; it does not say how. Do only the current
follow-up, keep every earlier verification passing, then stop and paste the last lines and statuses.
One directory, one wolf module, one `main`. GNU make is the oracle for everything but the refusals: when
in doubt, run both and diff.

The goal: an `mk` we would publish under wolffe-lang as a tool built by wollf. "The corpus passes" is
not the bar; "a stranger points it at their own Makefile and it does what make does" is.

---

### FOLLOW-UP 1 — A Makefile with a source file

The reviewer wrote the smallest real Makefile there is, in an empty directory with `src.txt` present:

```
all: out.txt

out.txt: src.txt
	cp src.txt out.txt
```

`make` copies the file and exits 0. `mk` prints `*** No rule to make target src.txt, needed by out.txt`
and exits 2. Every Makefile that compiles a program starts from files like `src.txt`, so today `mk` builds
nothing real; your corpus never has a prerequisite that is a file without a recipe, which is why no row
caught it.

Before you touch the code, write the answer to this in a comment at the top of `graph.lu`: README §2.1,
the out-of-date rule, names three cases for a prerequisite: it has a rule; it has no rule and does not
exist; it has no rule and exists. Which of the three does `run.lu` handle today, and which function decides?
What is a leaf's "built" state, and what does its mtime contribute to the out-of-date decision of the
target above it? What does `-n` print for a leaf? Then fix it, and add a corpus directory `leaf` (a
two-level build from two source files, one shared) that fails before the fix and passes after; N1, B1, B2
and B3 run on it.

Also: every message `mk` prints begins `make:`. The tool is `mk`; the README's shapes say `mk: ***`. Change
the prefix everywhere, and make the test compare GNU's text to yours with the prefix normalized.

**Verify:** the Makefile above builds, `mk -n` on it prints the `cp` line, a second `mk` prints the
up-to-date message and runs nothing, `touch src.txt` makes it run again; `./test.sh` includes `leaf` and
exits 0; paste the `leaf` rows.

--- END FOLLOW-UP 1 ---

---

### FOLLOW-UP 2 — Variables (FR-2, corpus `vars`)

The spec's corpus directory 3, `vars`, was never written. The reviewer wrote one:

```
A = one
B := $(A) two
A = uno
C ?= three
C ?= nope
D = x
D += y
E := $$HOME
all:
	@echo A=$(A) B=$(B) C=$(C) D=$(D) E=$(E) H=$(HOME_SET) O=$(OVR)
```

`HOME_SET=env make -s OVR=cli` prints `A=uno B=one two C=three D=x y E=/Users/you H=env O=cli`. `mk` prints
`B= two` after the shell complains `A: command not found`, and `E=33712HOME`. Two of the four flavours are
wrong in a way the shell can see. Questions to answer in `vars.lu`'s header before editing: at what moment
is `:=`'s right-hand side expanded, and at what moment is `=`'s? What does `$$` mean to make, and what must
the shell receive? Where is `${NAME}` handled? What does `+=` do to a `:=` variable versus a `=` one? Then
write `tests/corpus/vars` as the spec lists it (all four flavours, `+=`, `$$`, an env var, a command-line
override) and run N1 and B1 on it; add a `vars` case to `mk_test.lu` for each flavour.

**Verify:** `mk -n` and `make -n` on `vars` are byte-identical; `mk -s` and `make -s` print the same line;
`./test.sh` lists `ok N1 vars` and `ok B1 vars`.

--- END FOLLOW-UP 2 ---

---

### FOLLOW-UP 3 — `-j N` must mean N (FR-7, FR-10, J1)

The reviewer instrumented nine targets whose recipes record their start and end times and ran `mk -j 3`:
nine recipes were running at once. `wide` under `-j 2`, `-j 4`, `-j 8` and `-j 40` all take 0.24 s. The
J1 row says "never more than 8 `sleep` processes at once" and the model's J1 checked only the elapsed time,
so the row passed without testing the thing it is named for.

Think through in `run.lu`'s header: what is the state of a target between "started" and "finished", and
where is that count kept? What does the scheduler do when the count equals N: wait for which event, and
what does `std.process` offer for waiting on one of several children (you read `process.lu` in phase 4;
name the call)? When a child finishes, which targets become ready, and in what order are they started
(§2.2's discovery order)? What happens under `-k` when one fails while others run?

Then make J1 test what it says: the test records concurrency (recipes that write start/end timestamps, or
a `ps` sampler) and fails if the maximum exceeds N. Run it at N = 1, 2, 3, 8.

**Verify:** `wide` under `-j 2` takes about 4 s, `-j 4` about 2 s, `-j 8` about 1 s, `-j 1` about 8 s;
the recorded maximum concurrency equals N in each; `-j 8` output byte-identical to `-j 1`; exactly 40
echoes; `./test.sh` exits 0 with the new J1.

--- END FOLLOW-UP 3 ---

---

### FOLLOW-UP 4 — Refusing what is outside the subset (FR-1, corpus `refuse`, R1)

The reviewer fed `mk` one Makefile per construct the spec refuses. What came back: the refusal is printed to
stdout as `refused:1:include is not supported`, after the parsed rules were printed (why are they printed
at all without `-p`?); `include`, `ifeq`, `$(wildcard)`, `define` and `.SUFFIXES` then exit 0; pattern
rules, `|` and `::` exit 2. The spec's shape is `mk: Makefile:12: pattern rules are not supported` on
stderr, exit 2, for every one of the eight constructs, before anything is built or printed.

Questions: where in the parse does each construct become recognizable (a line's first token, a `$(`
followed by a word and a space, a target with `%`, a `|` in a prerequisite list)? Is a refusal an error
value the parser returns, or a print inside the parser? If it is an error, what does `main` do with it, and
what is the exit code's single source of truth? Write `tests/corpus/refuse/` with one Makefile per
construct (eight) and the R1 row over all of them.

**Verify:** each of the eight exits 2 with exactly one line on stderr, nothing on stdout, naming the
construct and the line; a Makefile with a refused construct on line 12 says `:12:`; `./test.sh` lists
`ok R1 refuse/<name>` eight times.

--- END FOLLOW-UP 4 ---

---

### FOLLOW-UP 5 — `-p` is the database, not the file (FR-11, P1)

`mk -p` prints the Makefile's lines back. The spec wants the parsed database: each variable with its
flavour and its expanded value, each rule with its prerequisites and recipe lines, in a stable order so a
golden file can be compared. Decide the format (look at what `make -p` prints for ideas, then choose a
smaller, stable one: sorted variable names, rules in file order), document it in `--help` and in a comment,
write `tests/corpus/vars/golden-p.txt`, and make P1 compare against it. Think about what "expanded value"
means for a `=` variable that references another variable defined later.

**Verify:** `mk -p` on `vars` matches the golden byte for byte; on `linear` it lists three rules with
their recipes; `./test.sh` lists `ok P1 vars`.

--- END FOLLOW-UP 5 ---

---

### FOLLOW-UP 6 — Continuations and comments in recipes (corpus 12)

*(superseded by the revised FOLLOW-UP 6 below; kept for the record)*

Corpus directory 12, `continuation`, was never written. The reviewer's version has a prerequisite list
joined by a backslash and a recipe line `@echo "one \` / `  two" # not a comment`. `make -n` prints the
recipe line with the backslash and the newline still in it, because inside a recipe the continuation
belongs to the shell; `mk -n` prints `echo "one    two"`. Read §2.1's two sentences on comments and
continuation again and decide what differs between a continuation in a variable or rule line and one in a
recipe line. Write the corpus directory and run N1 and B1 on it.

**Verify:** `mk -n` and `make -n` byte-identical on `continuation`; the built files identical; `#` inside
the recipe reaches the shell; `./test.sh` lists `ok N1 continuation`, `ok B1 continuation`.

--- END FOLLOW-UP 6 ---

---

### FOLLOW-UP 6 (revised 2026-10-23) — Continuations in recipes: the real site

You have spent sixty tool uses on `/tmp/mk-continuation` reading tab counts in `-p` and `-n` output. Stop
reading output. Here is what the shell actually receives, captured by putting a logging `sh` first on
`PATH` and running `mk` (no flags) on your own repro (`@echo "one \` / `<tab><tab>two"`):

    argv[1] = -c
    argv[2] = echo "one \          (11 bytes; nothing after the backslash)
    sh: -c: line 0: unexpected EOF while looking for matching `"'
    mk: *** [all] Error 2

Under `-j 2` the same Makefile hands the shell `echo "one \; <tab>two"`, because the scheduler joins
recipe entries with `; `. So `node.recipe` holds TWO entries for that one logical recipe line:
`@echo "one \` and `<tab>two"`. That is the whole bug. `-p` could not show it to you because `-p` prints
a tab in front of every stored entry, so two entries print exactly like one continued line; `-n` prints
each entry on its own line for the same reason. Count entries (`node.recipe.len`), never tabs.

The split happens in `join_continuations`, in the tab branch, before the `in_recipe && in_continuation`
test ever runs:

    if line.starts_with("\t") {
        // If we were building a non-recipe line, push it
        if current.len > 0 {          <-- fires for the recipe line you are still building
            (mut result).push(current)
            current = ""
            in_continuation = false
        }
        if in_recipe && in_continuation { ... }   <-- never true any more

The guard is meant for a pending non-recipe line, so it must be `if !in_recipe && current.len > 0`.
Your parse_makefile edits (`line[1..]`, the `find("\n")` branch) were correct and are not the problem; do
not touch them again.

Two more things the same function gets wrong, fix them in the same pass:

1. A continuation line inside a recipe need not start with a tab. The reviewer's case is
   `@echo "one \` / `  two" # not a comment` (two spaces). Today that second line falls into the
   non-recipe branch, the recipe is pushed half-finished, and `two" # not a comment` is parsed as a
   stray line; `mk -n` prints only `echo "one \`. Rule: while `in_recipe && in_continuation`, the next
   physical line continues the recipe whatever its first character is. Test that before the tab test.

2. What goes to the shell. POSIX and the host `make` pass the backslash-newline through to the shell and
   remove exactly one tab that follows it (that is why real `make` prints `one <tab>two`, one tab, from a
   file that has two). The host `make -n` on this Mac prints the raw line (both tabs). So: store the raw
   text; print the raw text for `-n` and `-p`; when building the shell command, delete one tab after
   each backslash-newline pair. Do this once, in a helper `recipe_for_shell(line: str) -> str` that both the serial
   path and the `-j` path call. Note that the `-j` path joins entries with `; ` — a continued recipe is
   one entry, so this is only correct once the entry count is right.

Corpus directory 12 is `tests/corpus/continuation/` (one Makefile, written 2026-10-22). Make sure it
covers: a prerequisite list continued across a line, one recipe line continued with a tab-indented second
line and one with a space-indented second line, and a `#` inside the quoted recipe text. Expected output for the
real run comes from `make`, for `-n` from `make -n`, same as every other corpus case.

**Verify:** with the logging `sh` trick (or `od -c` on what you print), `mk` hands the shell one
argument containing the backslash, the newline and one tab; `mk` on `continuation` exits 0 and the
built files match `make`'s; `mk -n` and `make -n` byte-identical on `continuation` (both the tab form
and the space form); `./test.sh` lists `ok N1 continuation`, `ok B1 continuation` and still 40 ok
elsewhere; `wolf test .` still 42 passed. Do not edit any file but `parse.lu`, `run.lu`, the corpus and
`test.sh` for this follow-up.

--- END FOLLOW-UP 6 (revised) ---

### FOLLOW-UP 6c (2026-10-23) — the giveaway: four exact changes, then stop

You went in circles on the `-j` path and the thread was compacted. Everything below was measured on a
copy of your tree as it stands (`wolf test .` 42 passed, `./test.sh` 43 passed, serial `mk` on
`continuation` byte-identical to `make`). Make these four changes in `run.lu`, exactly, in this order,
rebuilding once after each. Do not touch `parse.lu`, `graph.lu`, `vars.lu` or `main.lu`.

**1. The reap credits the wrong target (why `all` never runs under `-j` with two or more prerequisites).**
Both reap paths remove the finished child with "swap with last and pop" and then read the popped value:

    in_flight[found_idx] = in_flight[in_flight.len - 1]
    let flight = (mut in_flight).pop() else { continue }

`pop()` returns the LAST element, not the one at `found_idx`, so when `a` finishes, `b` is marked built
and `a` never is; `all` is never ready; the "nothing in flight and nothing ready" block then marks it
failed silently and returns 0. Measured with an `eprint` in each path: `launch a slot=0`, `launch b
slot=1`, `reap b slot=0`. Replace those two lines, at both sites, with the one-liner wolf's List has:

            // Remove the finished flight (the last element moves into its slot)
            let flight = (mut in_flight).swap_remove(found_idx)

**2. The "stuck" block hides errors.** Nothing should ever be marked failed without a word and exit 0.
Replace the body of `if remaining > 0 { ... }` at the end of the loop with:

            if remaining > 0 {
                // Nothing running and nothing ready: an internal error, never a silent success
                eprint("mk: *** internal error: {remaining} target(s) never became ready")
                return 2
            }

(After change 1 this block is unreachable on a correct graph; it stays as a loud guard.)

**3. `recipe_for_shell` puts a space where the backslash-newline was.** make passes the backslash-newline
to the shell and removes only the one tab after it; the shell deletes the pair inside double quotes. So
`echo "one \` / `<tab><tab>two"` must print `one <tab>two` (one space, one tab) and your output has two
spaces. Replace the function with:

fn recipe_for_shell(line: str) -> str {
    var result = line
    var i = 0
    while i < result.len - 1 {
        if result[i..i + 1] == "\\" && result[i + 1..i + 2] == "\n" {
            // Found a backslash-newline pair. Replace with a space.
            // Check if the next character is a tab and skip it.
            var next = i + 2
            if next < result.len && result[next..next + 1] == "\t" {
                next += 1
            }
            // Keep the backslash-newline for the shell; drop only the one tab after it
            result = result[0..i + 2] + result[next..]
            i += 2
            continue
        }
        i += 1
    }
    return result
}


**4. The `-j` path joins recipe lines with `; `, which is wrong three ways:** a `#` comment line swallows
every line after it on the same shell line (your `continuation` failure under `-j 2`, "unexpected EOF
while looking for matching `\"`"); a failing line does not stop the recipe; and the lines are printed all
at once before any runs, so the echo and the output do not interleave as make's do. Build the script
instead: `set -e` first; for each line, a `printf` of the line (unless `@` or `-s`), then the line alone
inside `( :` … `)` so a comment, a `cd` or a continuation stays inside its own subshell; a `-` line gets
`|| echo "mk: [NAME] Error $? (ignored)" >&2`. Replace the loop body from `if !is_silent && !silent {`
through `combined = combined + shell_line` with (note `ignore_errors` must be declared as a `var` next
to `is_silent` and set where `-` is stripped):

                // The script prints each line right before running it (as make does, so the
                // echo and the command's output interleave), runs it in its own subshell so a
                // `#` comment, a `cd` or a continuation stays inside its line, and stops at the
                // first failure unless the line was `-` prefixed.
                let shell_line = recipe_for_shell(line)
                if combined.len == 0 {
                    combined = "set -e\n"
                }
                if !is_silent && !silent {
                    let quoted = line.replace("'", "'\\''")
                    combined = combined + "printf '%s\\n' '" + quoted + "'\n"
                }
                if ignore_errors {
                    combined = combined + "( :\n" + shell_line + "\n) || echo \"mk: [" + name + "] Error $? (ignored)\" >&2\n"
                } else {
                    combined = combined + "( :\n" + shell_line + "\n)\n"
                }

Then `process.push_arg(mut cmd, combined)` as before. Measured with this exact code: `continuation`
under `-j 2` byte-identical to `make`; `linear`, `diamond`, `fail`, `wide` identical on sorted output
and exit codes; `-false` prints `mk: [all] Error 1 (ignored)` and continues; `cd /tmp` on one line does
not move the next line.

**5. One more difference, not a bug in the four above:** under `-j`, an up-to-date goal prints nothing
where the serial path (and make) print `mk: Nothing to be done for `all'.` (corpora `ignore`, `wide`
on the second run). Add the same message to the parallel path where a goal is found up to date with
nothing rebuilt beneath it.

Cleanup: delete `tests/corpus/continuation/sh` (a stray copy of the logging-shell trick; the corpus
directory must hold the Makefile only) and any `a.txt b.txt c.txt` left there.

**Verify, then stop and report the last lines:** `wolf build main.lu -o mk` exit 0; `wolf test .` 42;
`./test.sh` 43 ok, 0 failed; for every corpus directory, `mk -j 2` and `make -j 2` agree on the sorted
output and the exit code (add this as row J2 in `test.sh` while you are there); `mk -j 2 -C
tests/corpus/continuation` byte-identical to `make -j 2` there. Do not run anything twice to "see it
again"; one build, one run per check.

--- END FOLLOW-UP 6c ---

### FOLLOW-UP 7 — The test script is the product's proof

`test.sh` printed `PASS: B1:ignore` when `tests/corpus/ignore` did not exist (the reviewer ran it in a copy
without the corpus): a row that cannot find its directory must fail, not pass. The spec's rows read
`ok <row> <dir>` per line and every row runs on every directory the spec names for it; today nine
directories and nine rows run, twelve and eleven are specified.

- Build the matrix from two lists at the top of the script (rows, directories per row) so a missing
  directory, a missing golden, a missing `make` or a missing `wolf` is a loud failure with exit 2.
- Each row makes its own fresh copies with `mktemp -d` and removes them; nothing is written under `/tmp`
  by a fixed name and nothing in `tests/corpus` is modified by a run.
- The summary says how many rows ran, and the exit status is 0 only when every expected `ok` line
  appeared (count them against the matrix, not against "no FAIL printed").
- Break something on purpose (one character in `graph.lu`'s out-of-date rule), show which rows catch it,
  restore it.

**Verify:** `./test.sh; echo $?` → `0`, with `ok <row> <dir>` lines for every cell of the matrix (paste the
count); the deliberate break shows at least one `FAIL`; a run from a copy without `tests/` exits 2 with a
message.

--- END FOLLOW-UP 7 ---

---

### FOLLOW-UP 8 — Read it as a stranger

Read every `.lu` file top to bottom as someone who has never seen it (2,200 lines). In `REVIEW.md`, one
section per file: what it owns; what is no longer called; what is done twice (the serial build and the
scheduler both decide out-of-date-ness and both print messages: should they?); what is a hand-rolled
version of something `std` provides; which comments describe what the code did rather than what it does.
Then act on it without changing behaviour: delete dead code, unify the two build paths' decisions behind
one function, give every message one shape (`mk: <what>` on stderr; `mk: *** …` for the fatal ones), and a
one-line doc comment per public function saying what it answers. The proof that behaviour did not change
is `./test.sh` and `wolf test .` green before and after with no edits to the tests.

**Verify:** `REVIEW.md` written; `wolf fmt --check *.lu`; `wolf build` warning-free; `./test.sh` exits 0;
`wc -l *.lu` before and after in the note.

--- END FOLLOW-UP 8 ---

---

### FOLLOW-UP 9 — Ship it

- `README.md` is the spec you were given; keep it as `SPEC.md` and write a user's README: what `mk` is in
  two sentences (a make for the subset, refusing the rest by name), install, usage with real pasted output,
  the subset table (what is accepted, what is refused and with which message), the out-of-date rule, `-j`
  and `-k` semantics, exit codes, how to run the tests and what the oracle is (GNU make beside it), and
  measured numbers (`wide` at `-j 1/8`) with the date and machine.
- `mk --version` printing a version and the wolf it was built with.
- `CHANGELOG.md` with the first entry, including what is not supported, by name.
- `LICENSE` (ask which; default to the licence wolffe-lang's other tools use, and say so).
- A clean directory: no `.lu-cache`, no `mk` binary, no scratch files; the README lists every file and
  what it is for.
- The honesty line at the top of the README: written by wollf-v7sf3 under this harness with human review,
  with the test matrix as the reason to trust it.

**Verify:** `ls` matches the README's file list; a fresh clone builds and passes `./test.sh` with nothing
else present; `mk --help` matches the README's usage block byte for byte; paste the README's subset table.

--- END FOLLOW-UP 9 ---
