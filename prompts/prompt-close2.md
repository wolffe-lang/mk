# mk — closeout 2 of 8: the parallel path honours -n, -s and -k (giveaway allowed)

Edit in place, never rewrite a whole file, and rebuild `mk` after each change (`wolf build main.lu -o mk`). `build_goals_serial` in `run.lu` gets all three of these right; `build_goals_parallel` does not. Make the parallel path take the same decisions. Calling the serial path's code is fine, and so is moving it into a shared function. One commit per item.

### CLOSE 2a — `-n -j N` must not run anything

`build_goals_parallel` takes `dry_run` and never reads it, so **`mk -n -j 2` runs the recipes**. A dry run that writes files is the worst bug left. From clean (each in a fresh copy of the directory):

| dir | `make -n -j 2` prints | files after | `mk -n -j 2` today |
|---|---|---|---|
| `phony` | `printf "prog" > prog` and `echo "built prog"`, exit 0 | none | runs them: prints `built prog`, writes `prog` |
| `vars` | `echo A=uno B=one two C=three D=x y E=$HOME H= O= > vars.out`, exit 0 | none | prints nothing, writes `vars.out` |
| `fail` | `exit 3` and `printf "result" > result`, exit 0 | none | runs them: `mk: *** [result] Error 3`, exit 2 |

Under `-n`, every recipe line of every out-of-date target is printed and nothing is started, `@` lines included, exactly as the serial `-n` already does. Commit: `-n -j N prints the recipes and runs nothing`.

### CLOSE 2b — `-s -j N` hides the ignored error

In `tests/corpus/ignore`, `make -s -j 2` prints nothing and exits 0. `mk -s -j 2` prints `mk: [result] Error 1 (ignored)`. The parallel path's `-` line appends `|| echo "mk: [NAME] Error $? (ignored)" >&2` whatever `-s` says. Under `-s`, leave the echo out (keep the `|| true` behaviour, so the next line still runs). Commit: `-s -j N hides the ignored-error line`.

### CLOSE 2c — `-k -j N` and a missing prerequisite

In `tests/corpus/missing`, `make -k -j 2` prints these two lines and exits 2:

```
make: *** No rule to make target `missing_file', needed by `result'.
make: Target `all' not remade because of errors.
```

`mk -k -j 2` prints only the first. The parallel path returns 2 the moment it meets the missing prerequisite ("Always exit 2 … regardless of -k"), before the end-of-run loop that prints `not remade`. Under `-k`:
- mark the target failed;
- keep building whatever does not depend on it;
- let the end-of-run code print the `not remade` line for each goal it blocked;
- then exit 2.

Without `-k`, keep today's immediate stop. Commit: `-k -j N reports goals a missing prerequisite blocked`.

**Verify** (paste the output): run this loop with `bash` from the project directory; it prints `SAME` for every line.

```bash
for d in linear diamond phony auto ignore leaf vars continuation fail missing cycle wide; do
  for fl in "-n -j 2" "-s -j 2" "-k -j 2" "-s -k -j 2"; do
    rm -rf /tmp/mkc /tmp/mkm; cp -R tests/corpus/$d /tmp/mkc; cp -R tests/corpus/$d /tmp/mkm
    for x in /tmp/mkc /tmp/mkm; do (cd $x && rm -f a b c d a.txt b.txt c.txt base left right other result out1.txt out2.txt prog vars.out t[0-9][0-9]); done
    a=$(cd /tmp/mkm && /usr/bin/make $fl 2>&1 | sed 's/^make:/TOOL:/' | sort; echo "exit ${PIPESTATUS[0]}"; ls)
    b=$(cd /tmp/mkc && $OLDPWD/mk $fl 2>&1 | sed 's/^mk:/TOOL:/' | sort; echo "exit ${PIPESTATUS[0]}"; ls)
    [ "$a" == "$b" ] && echo "SAME $d $fl" || echo "DIFF $d $fl"
  done
done
```

Then `wolf test .` and `./test.sh` green, and `git log --oneline | head -4`. Then stop.
