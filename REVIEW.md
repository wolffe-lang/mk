# Review

## graph.lu (224 lines)

**Owns:** `Node`, `Graph` structs; `add_node` (merge across rules); `is_out_of_date` (the out-of-date decision); `newer_prereqs` (which prereqs are newer); `build_graph` (construct the graph from the parsed database, expanding variables in prerequisite names).

**No longer called:** Nothing.

**Done twice:** `is_out_of_date` is called by both the serial path (`build_recursive`) and the parallel path (`build_goals_parallel`). The decision logic is shared — good. But the *reaction* to the decision diverges: the serial path prints "Nothing to be done" / "is up to date" in `build_recursive`; the parallel path prints the same in `build_goals_parallel`. The message shape is the same, which is correct.

**Hand-rolled std:** `newer_prereqs` duplicates the mtime-comparison logic of `is_out_of_date` (lines 133-155 vs 160-192). The two functions share the same loop structure and the same `v > 0` / `v < 0` checks. They could share a helper, but the overlap is small and the duplication is not harmful.

**Stale comments:** The doc comment at lines 6-23 describes the three cases for a prerequisite and how `run.lu`'s `build_recursive` handles them. This is accurate. The comment at line 16 ("A leaf's built state is `1`") is now inaccurate: the parallel path sets it to `0` for up-to-date targets. The serial path also sets it to `0` for leaves (line 160 of `run.lu`). The comment should say "A leaf's built state is `0` (present, not rebuilt)."

## main.lu (336 lines)

**Owns:** CLI parsing (`Flags` struct, `parse_flags`); `main` entry point; `build_vars` (construct the variable table from parsed assignments); `-p` output delegation to `print_database`.

**No longer called:** `print_usage` is called only from the `help` arm of `parse_flags`. `print_flags` is called only from the `--debug-opts` path. Both are still used.

**Done twice:** The `else |e|` handler for `parse_flags` (lines 245-255 and 257-265) is duplicated: both arms handle `help` and `parse` identically. The first copy is for the debug path, the second for the normal path. They could share a helper, but the duplication is small.

**Hand-rolled std:** `parse_arg` (lines 49-84) is a simple string-matching dispatcher. `extract_jobs` (lines 87-100) parses `-jN`. Both are straightforward.

**Stale comments:** The doc comment at lines 1-9 describes the file layout. Accurate.

## parse.lu (507 lines)

**Owns:** `Assignment`, `Rule`, `Phony`, `Refusal`, `Database` structs; `join_continuations` (join `\`-continued lines); `strip_comment` (remove `#` comments); `check_refusal` (reject unsupported constructs); `parse_assignment`, `parse_rule`, `parse_phony` (parse individual line types); `parse_makefile` (parse the whole file); `parse_makefile_file` (read from disk); `print_database` (format for `-p`).

**No longer called:** Nothing.

**Done twice:** `parse_assignment` checks for `:=`, `?=`, `+=`, and bare `=` in sequence (lines 204-256). The logic is correct but verbose. `parse_rule` and `parse_phony` share the `:` splitting logic.

**Hand-rolled std:** `join_continuations` is a state machine with `in_recipe`, `in_continuation`, and `current` variables. It handles recipe continuations (preserving newlines) and non-recipe continuations (joining with spaces). The logic is complex but correct.

**Stale comments:** The doc comment at lines 1-5 describes the parser's responsibilities. Accurate. The comment at line 46 ("A trailing `\` joins with the next line") is accurate for non-recipe lines.

## run.lu (659 lines)

**Owns:** `BuildResult`, `Flight` structs; `recipe_for_shell` (prepare a recipe line for the shell); `build_target` (build a single target's recipe); `build_recursive` (serial DFS build); `discover_targets` / `discover_recursive` (topological order); `prereqs_done` (check if all prereqs are in the built map); `build_goals` (dispatch to serial or parallel); `build_goals_serial` (serial build); `build_goals_parallel` (parallel build with ready queue).

**No longer called:** Nothing.

**Done twice:** The serial and parallel paths both:
1. Check `is_out_of_date` and react with "Nothing to be done" / "is up to date" messages.
2. Expand variables and automatic variables in recipe lines.
3. Handle `@` (silent) and `-` (ignore errors) prefixes.
4. Handle leaf files (no rule, file exists).

The out-of-date decision is shared (`is_out_of_date` in `graph.lu`). The message shape is the same. The variable expansion is shared (`expand` and `expand_auto` in `vars.lu`). The leaf-file handling diverges: the serial path checks `fs.exists` in `build_recursive`; the parallel path checks it in the `else` arm of `map.get(g.nodes, name)`.

**Hand-rolled std:** `recipe_for_shell` is a character-by-character scanner. `build_goals_parallel` is a state machine with `in_flight`, `started`, `failed`, and `built` maps.

**Stale comments:** The doc comment at lines 1-25 describes the scheduler's responsibilities. Accurate. The comment at line 367 ("built: name -> 1 (rebuilt), -1 (cycle-broken/skipped)") is now incomplete: `0` means "present, not rebuilt."

## Cross-cutting observations

1. **Message shape:** All messages use `mk:` prefix. Fatal errors use `mk: ***`. This is consistent.

2. **Out-of-date decision:** Shared between serial and parallel paths via `is_out_of_date`. Good.

3. **Leaf handling:** Diverges between serial and parallel paths. The serial path checks `fs.exists` in `build_recursive`; the parallel path checks it in the `else` arm of `map.get(g.nodes, name)`. The behaviour is the same.

4. **`built` map values:** `1` = rebuilt, `0` = present not rebuilt, `-1` = cycle-broken. The parallel path's `!is_out_of_date` branch sets `0`; the serial path does not set `built` for up-to-date targets (they remain absent from the map). This is a minor inconsistency, but it does not affect behaviour because `is_out_of_date` treats absent entries the same as `0` entries (the `else 0` in `map.get(built, p) else 0`).
