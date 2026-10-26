Stop editing `normalize` in test.sh and stop re-reading the harness. The 52 failing rows are one bug, in your own code, and it is a space.

`mk_prefix` returns `"mk: "` (with the trailing space) and every `eprint` that uses it adds another space before the message:
`eprint("{mk_prefix(makelevel)} *** No rule …")`. The result is `mk:  *** No rule …` with two spaces where gmake prints one. Verify it yourself in one row:

```
cd tests/corpus/missing && gmake 2>&1 | head -1; ../../../mk 2>&1 | head -1
```

Fix it in one place: make `mk_prefix` return `"mk:"` / `"mk[{level}]:"` without the trailing space and leave every format string as it is (`"{mk_prefix(makelevel)} *** …"`, `"{mk_prefix(makelevel)} Circular …"`, `"{mk_prefix(my_level)} *** No rule …"`). Rebuild, `./test.sh | tail -1`, and the baseline/B3/M1/C1 rows come back. Do not touch the message texts.

Then two more things before the recursion rows:

1. `wolf test .` is REJECTED (0 passed): `mk_test.lu:25` calls `parse_makefile` with 6 arguments where it now takes 7, and the `Database` literal on the same line lacks the field `included_files` added by P1.13. Add the argument and the field at that one call site so the 50 unit tests run again. This must be green before you commit anything.

2. The `[N]` prefix in test.sh: gmake prints `gmake[1]:`, mk prints `mk[1]:`. `normalize` only maps `(gmake|make|mk):`. Change that ONE regex to keep the level on both sides: `s/^(gmake|make|mk)(\[[0-9]+\])?:/MAKE\2:/`. Nothing else in test.sh changes.

Order: the prefix space → `wolf test .` green → `./test.sh | tail -1` back to 155 expected with the pre-P1.14 count passing → the regex → the three recursion rows (`levels`, `flags -k -j2`, `dry -n`). Commit red, then the commit the prompt names. If a recursion row still differs, paste the two normalized outputs side by side before changing anything.
