# mk — v3 (multi-phase, low give-away)

This build is delivered as **phases**, pasted one at a time. Do **only** the current
phase, make its **verification** pass, then stop and wait for the next. Keep earlier
phases working. One directory, one wolf module, one `main`.

---

### PHASE 0 — Setup & spec

First run `cp ../../README.md ./README.md && cp ../../../WOLF-NOTES.md ./WOLF-NOTES.md`,
then read both fully. Check `make --version` says GNU. Write `main.lu` parsing the flags
of README §4 (`-f -C -n -s -k -j [N] -p`, `NAME=VALUE`, goals) into a struct printed by
`--debug-opts`; `--help` → usage, exit 0; unknown flag → `mk: …`, exit 2. Decide your
file layout and write it at the top of `main.lu`.

**Verify:** `wolf build main.lu -o mk` warning-free; `./mk --help; echo $?` → `0`;
`./mk -z; echo $?` → `2`; `wolf fmt --check *.lu`.

--- END PHASE 0 ---

---

### PHASE 1 — Parser and `-p` (M1; FR-1, FR-2, FR-11)

Logical lines (continuations, comments), the four assignment flavours and `+=`,
rules with tab recipes, `.PHONY`, the refusals by name with line numbers, `-p` in a
stable format. Write `tests/corpus/vars`, `continuation`, `refuse`, and the golden for
`-p` on `vars`. Tests in `mk_test.lu` for the parser and the flavours.

**Verify:** P1 and R1 of README §7.2; `wolf test .` green.

--- END PHASE 1 ---

---

### PHASE 2 — Serial build (M2; FR-3, FR-4, FR-5, FR-6)

Automatic variables, the out-of-date rule with ms mtimes, `.PHONY`, recipe execution
through `sh -c` with `@`/`-`/echo, `-n`, `-s`, goals. Corpus: `linear`, `diamond`,
`phony`, `auto`, `ignore`. `test.sh` with N1, B1, B2, B3 against GNU make on fresh
copies.

**Verify:** N1, B1, B2, B3 on those five; `make -n` and `mk -n` byte-identical.

--- END PHASE 2 ---

---

### PHASE 3 — Failures, `-k`, missing, cycles (M3; FR-5, FR-8, FR-9)

The error shapes to the letter; `-k`; the no-rule message; circular-dependency
dropping. Corpus: `fail`, `missing`, `cycle`.

**Verify:** F1, M1, C1.

--- END PHASE 3 ---

---

### PHASE 4 — `-j N` (M4; FR-7, FR-10)

The scheduler over the discovery order with up to N concurrent targets; read
`std/process/process.lu` to choose between `poll()` and per-child waits and say why.
Corpus: `wide`, and `diamond` with a `sleep 1` base. `-C`, `-f`.

**Verify:** J1 (timing, identical files, ≤ 8 concurrent `sleep`s sampled by `ps`), J2.

--- END PHASE 4 ---

---

### PHASE 5 — The whole corpus (M5)

`test.sh` over every row and every directory; `-p` golden; a `--graph`-free finish.

**Verify:** `./test.sh; echo $?` → `0`; `wolf test .` and `wolf fmt --check *.lu` clean.
Paste the last lines and statuses in your final message.

--- END PHASE 5 ---
