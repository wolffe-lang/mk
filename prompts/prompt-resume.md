# mk — resuming in a fresh thread

You are picking up `mk`, a small `make` written in wolf, in this directory (`v3/`). The previous thread
ended mid-way through a follow-up; nothing it did is lost, the tree on disk is the state of record. This
prompt tells you what the project is, what to read, where it stands, and how to work in this thread.
Read it all before running anything.

## 1. What the project is

One directory, one wolf module, one `main`: `main.lu` (CLI), `parse.lu` (Makefile → database),
`vars.lu` (variables and `$@ $< $^ $?`), `graph.lu` (rules → dependency graph, out-of-date test),
`run.lu` (serial build, `-n`, and the `-j N` scheduler on `process.start`/`process.poll`), `mk_test.lu`
(unit tests, `wolf test .`). `test.sh` runs every directory under `tests/corpus/` against GNU `make`
(the oracle for everything except the refusals) and prints one `ok ROW case` line per check.

The goal is an `mk` we publish under wolffe-lang as a tool built by wollf. "The corpus passes" is not
the bar; "a stranger points it at their own Makefile and it does what make does" is.

## 2. Read these, in this order, once

1. `README.md` — the spec. §2.1 (the Makefile subset, including the two sentences on comments and
   continuations), §3 (the numbered requirements), §7 (the corpus and the rows N1, B1, F1, M1, C1, J1,
   P1, R1), §7.3 (Definition of Done).
2. `WOLF-NOTES.md` — the wolf surface you need; §2 is the parts of the language that bite, §4 the
   measured process rules, §5 the working habits. Do not guess at std names: this file has them.
3. `prompt-followup.md` — the follow-up series. FOLLOW-UPs 1–5 are done and verified (see §3 below).
   The current task is **FOLLOW-UP 6 (revised 2026-10-23)**; the original FOLLOW-UP 6 above it is
   superseded and kept only for the record. FOLLOW-UPs 7–9 come after, one at a time.
4. `JUDGE.md` — what the reviewer found after v3 and what the earlier thread struggled with.
5. The six `.lu` files, each once, top to bottom (about 2,000 lines in all). Then `test.sh` and
   `ls tests/corpus`.

## 3. Where it stands (verified 2026-10-23 00:45 on this Mac)

- `wolf build main.lu -o mk` exits 0. `wolf test .`: 42 passed. `./test.sh`: 40 ok, 0 failed.
- Verified by hand, outside the corpus: a Makefile with a real source file rebuilds and then says
  "Nothing to be done" (FU 1); `=`, `:=`, `?=`, `+=`, `$$`, command-line overrides, `mk -n` identical
  to `make -n` (FU 2); `-j 3` on nine independent targets never exceeds three children (FU 3); pattern
  rules, `include`, functions, `define` each refused with `mk: Makefile:LINE: X is not supported` (FU 4);
  `-p` prints the database, not the file (FU 5).
- Open: recipe continuations (FU 6). A recipe line ending in `\` is stored as two recipe entries, so a
  serial run hands the shell only the first half (`echo "one \`, "unexpected EOF", `Error 2`), and
  `-j` joins the halves with `; `. The revised FOLLOW-UP 6 names the exact line in
  `parse.lu::join_continuations`, the two companion faults, and the shell rule; it was written from a
  captured `sh` argv, not from reading `-n` output. Start there. Do not re-derive it from tab counts in
  `-p` or `-n`: `-p` prints a tab before every stored entry, so two entries look like one continued line.

## 4. How to work in this thread

The last thread died because its context could not be compacted: too much tool output. Keep output
small and keep it moving.

- Read a file once. Afterwards use `grep -n` and `sed -n A,Bp` for the lines you need; never `cat` a
  whole `.lu` again, never page through `test.sh` twice.
- Never dump bytes. `od -c | head -3` on the one string you care about, not `xxd` on a file.
- Rebuild and rerun only after an edit. Running the same command twice to "see it again" buys nothing
  and costs context.
- When a verification fails the same way twice, stop editing. Change the hypothesis, and prove the new
  one with an instrument (an `eprint` of a `.len`, a logging `sh` on `PATH`) before the next edit.
- Keep every earlier verification passing: after each follow-up, `wolf test .` and `./test.sh` in full,
  and report the last lines and the counts, not the whole output.
- One follow-up at a time. Finish FOLLOW-UP 6 (revised), stop, report; then 7, 8, 9 from
  `prompt-followup.md`, each on its own.

Begin with §2. When you have read everything, say in five lines what `join_continuations` does today
and what FOLLOW-UP 6 (revised) asks you to change, then do it.
