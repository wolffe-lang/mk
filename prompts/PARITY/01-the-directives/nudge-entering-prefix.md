Stop re-deriving what MAKELEVEL "should" be. Your own probe already answered it: with `MAKELEVEL=1` in the environment the error line printed `mk[1]: *** [Makefile:3: all] Error 127` — so `makelevel` is read correctly and `mk_prefix` works. The lines that stay `mk:` at every level are the ones that never call `mk_prefix` at all.

Run this once and read the line numbers:

```
grep -n "Entering directory\|Leaving directory" main.lu
```

Nine `print("mk: Entering directory …")` / `print("mk: Leaving directory …")` lines, main.lu ~705–734, carry the literal `mk:`. gmake prints `gmake[1]: Entering directory …` at level 1 (your gmake output: `MAKE[1]: Entering directory …/sub`). That is the whole `levels` diff.

Fix, in `main()` only:

1. Before the `if f.dir.len > 0 {` block that changes directory (the -C block runs *before* `run()` reads MAKELEVEL at ~431), read the level once:

```
    let level = (env.get("MAKELEVEL") else "0").to_int() else 0
```

2. Replace the literal `mk:` in those nine prints with `{mk_prefix(level)}`:

```
    print("{mk_prefix(level)} Entering directory '{abs_dir}'")
    print("{mk_prefix(level)} Leaving directory '{abs_dir}'")
```

and the three `eprint("mk: *** {f.dir}: No such file or directory.  Stop.")` lines the same way. Do not touch `mk_prefix`, `run.lu`, `vars.lu` or the harness.

3. Rebuild (`wolf build main.lu -o mk`), then `./test.sh | tail -1`.

If the `levels` row still differs, the remaining difference is the exit code (the harness said make 127, mk 2). Before changing anything, run the row's exact command for both tools and paste the two normalized outputs and both exit codes side by side in your reply, then name the one line that differs. One row at a time: `levels`, then `flags -k -j2`, then `dry -n`. Commit when the three are green.
