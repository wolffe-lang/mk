#!/bin/bash
# test.sh — corpus testing against GNU make
#
# Matrix: rows × directories. Every cell must pass.
# A missing directory, golden, mk binary, or make binary is a loud failure (exit 2).
# Each row works in its own mktemp -d copy; nothing is written under tests/corpus.

set -euo pipefail

MK="./mk"
MAKE="${MAKE:-gmake}"
CORPUS_DIR="tests/corpus"
ROOT=$(pwd)

# Matrix: each line is "row dir"
# N1/B1/B2 run on the standard set; B3 on a subset; the rest on their own dirs.
STANDARD="linear diamond phony auto ignore leaf vars continuation"
B3_DIRS="linear diamond auto ignore leaf"
B3_SOURCES="a base a result shared.txt"

# Pre-flight: mk and make must exist
if [ ! -x "$MK" ]; then
    echo "ERROR: $MK not found or not executable"
    exit 2
fi
if ! command -v "$MAKE" >/dev/null 2>&1; then
    echo "ERROR: $MAKE not found"
    exit 2
fi
# Pre-flight: the oracle must be GNU Make 4.4.1
MAKE_VERSION=$("$MAKE" --version | head -1)
if [ "$MAKE_VERSION" != "GNU Make 4.4.1" ]; then
    echo "ERROR: $MAKE is not GNU Make 4.4.1 (got: $MAKE_VERSION)"
    exit 2
fi

# Collect all unique directory names from the matrix
ALL_DIRS="$STANDARD"
for dir in fail missing cycle wide diamond refuse vars; do
    ALL_DIRS="$ALL_DIRS $dir"
done
# Deduplicate
ALL_DIRS=$(echo "$ALL_DIRS" | tr ' ' '\n' | sort -u)

# Pre-flight: every corpus directory must exist
for dir in $ALL_DIRS; do
    if [ ! -d "$CORPUS_DIR/$dir" ]; then
        echo "ERROR: corpus directory $CORPUS_DIR/$dir does not exist"
        exit 2
    fi
done
# Pre-flight: golden files must exist
if [ ! -f "$CORPUS_DIR/vars/golden-p.txt" ]; then
    echo "ERROR: golden file $CORPUS_DIR/vars/golden-p.txt does not exist"
    exit 2
fi

# Build the full matrix (newline-separated "row dir" pairs)
MATRIX=""
for dir in $STANDARD; do
    MATRIX="$MATRIX
N1 $dir
B1 $dir
B2 $dir"
done
for dir in $B3_DIRS; do
    MATRIX="$MATRIX
B3 $dir"
done
MATRIX="$MATRIX
F1 fail
M1 missing
C1 cycle
J1 wide
J2 diamond
R1 refuse
P1 vars"
for rows in "$CORPUS_DIR"/*/rows; do
    d=$(basename "$(dirname "$rows")")
    while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; esac
        MATRIX="$MATRIX
R $d $line"
    done < "$rows"
done
MATRIX="$MATRIX
RJ refuse
E1 wide"

# Count expected rows (trim leading newline first)
EXPECTED=$(echo "$MATRIX" | tail -n +2 | wc -l)
PASS=0
FAIL=0
OK_LINES=""

# Normalize prefix: replace "mk:" or "gmake:" with "make:" so the comparison is fair
normalize() {
    sed -E 's/^(gmake|make|mk):/MAKE:/'
}

# Clean a copy of a corpus directory
clean_copy() {
    local dir="$1"
    local corpus="$2"
    local tracked
    tracked=$(git ls-files "$CORPUS_DIR/$corpus" | sed "s|^$CORPUS_DIR/$corpus/||")
    (cd "$dir" && find . -type f | sed 's|^\./||' | while read -r f; do
        printf '%s\n' "$tracked" | grep -qxF "$f" || rm -f "$f"
    done)
}

# Run a test in a fresh copy of the corpus
run_test() {
    local row="$1"
    local dir="$2"
    local corpus_dir="$CORPUS_DIR/$dir"

    # Check the corpus directory exists
    if [ ! -d "$corpus_dir" ]; then
        echo "FAIL: $row $dir (directory missing)"
        FAIL=$((FAIL + 1))
        return
    fi

    # Create a fresh copy
    local copy=$(mktemp -d)
    cp -R "$corpus_dir/." "$copy/"

    case "$row" in
        N1) test_n1 "$copy" "$dir" ;;
        B1) test_b1 "$copy" "$dir" ;;
        B2) test_b2 "$copy" "$dir" ;;
        B3) test_b3 "$copy" "$dir" ;;
        F1) test_f1 "$copy" "$dir" ;;
        M1) test_m1 "$copy" "$dir" ;;
        C1) test_c1 "$copy" "$dir" ;;
        J1) test_j1 "$copy" "$dir" ;;
        J2) test_j2 "$copy" "$dir" ;;
        R1) test_r1 "$copy" "$dir" ;;
        P1) test_p1 "$copy" "$dir" ;;
        RJ) test_rj "$copy" "$dir" ;;
        E1) test_e1 "$copy" "$dir" ;;
    esac

    # Clean up the copy
    rm -rf "$copy"
}

# N1: -n output byte-identical
test_n1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    local copy_real
    copy_real=$(cd "$copy" && pwd -P)
    local mk_out=$("$MK" -C "$copy" -n 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    local make_out=$("$MAKE" -C "$copy" -n 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    if [ "$mk_out" = "$make_out" ]; then
        echo "ok N1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: N1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# B1: files identical after build
test_b1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    "$MK" -C "$copy" >/dev/null 2>&1 || true
    local mk_files=$(cd "$copy" && ls -1 2>/dev/null | sort)
    local mk_bytes=$(cd "$copy" && cat * 2>/dev/null | md5)
    clean_copy "$copy" "$dir"
    "$MAKE" -C "$copy" >/dev/null 2>&1 || true
    local make_files=$(cd "$copy" && ls -1 2>/dev/null | sort)
    local make_bytes=$(cd "$copy" && cat * 2>/dev/null | md5)
    if [ "$mk_files" = "$make_files" ] && [ "$mk_bytes" = "$make_bytes" ]; then
        echo "ok B1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: B1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# B2: second run prints "Nothing to be done" (or rebuilds phony/continuation)
test_b2() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    "$MK" -C "$copy" >/dev/null 2>&1 || true
    local second=$("$MK" -C "$copy" 2>&1)
    if [ "$dir" = "phony" ]; then
        if echo "$second" | grep -q "built prog"; then
            echo "ok B2 $dir"
            PASS=$((PASS + 1))
        else
            echo "FAIL: B2 $dir"
            FAIL=$((FAIL + 1))
        fi
    elif [ "$dir" = "continuation" ]; then
        if echo "$second" | grep -q "built a.txt"; then
            echo "ok B2 $dir"
            PASS=$((PASS + 1))
        else
            echo "FAIL: B2 $dir"
            FAIL=$((FAIL + 1))
        fi
    else
        if echo "$second" | grep -q "Nothing to be done"; then
            echo "ok B2 $dir"
            PASS=$((PASS + 1))
        else
            echo "FAIL: B2 $dir"
            FAIL=$((FAIL + 1))
        fi
    fi
}

# B3: touch one source, same recipes run
test_b3() {
    local copy="$1" dir="$2"
    local source=""
    case "$dir" in
        linear) source="a" ;;
        diamond) source="base" ;;
        auto) source="a" ;;
        ignore) source="result" ;;
        leaf) source="shared.txt" ;;
    esac
    local copy_real
    copy_real=$(cd "$copy" && pwd -P)
    clean_copy "$copy" "$dir"
    "$MK" -C "$copy" >/dev/null 2>&1 || true
    touch -d "2026-10-22 19:00:00" "$copy/$source"
    local mk_out=$("$MK" -C "$copy" -n 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    clean_copy "$copy" "$dir"
    "$MAKE" -C "$copy" >/dev/null 2>&1 || true
    touch -d "2026-10-22 19:00:00" "$copy/$source"
    local make_out=$("$MAKE" -C "$copy" -n 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    if [ "$mk_out" = "$make_out" ]; then
        echo "ok B3 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: B3 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# F1: fail corpus exits 2, error shape, -k builds independent target
test_f1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    local mk_exit=0
    "$MK" -C "$copy" >/dev/null 2>&1 || mk_exit=$?
    local make_exit=0
    "$MAKE" -C "$copy" >/dev/null 2>&1 || make_exit=$?
    if [ "$mk_exit" -eq 2 ] && [ "$make_exit" -eq 2 ]; then
        local mk_err=$("$MK" -C "$copy" 2>&1)
        local make_err=$("$MAKE" -C "$copy" 2>&1)
        if echo "$mk_err" | grep -q '\*\*\* \[Makefile:[0-9]*: result\] Error 3' && \
           echo "$make_err" | grep -q '\*\*\* \[Makefile:[0-9]*: result\] Error 3'; then
            clean_copy "$copy" "$dir"
            local mk_k=$("$MK" -C "$copy" -k all other 2>&1)
            clean_copy "$copy" "$dir"
            local make_k=$("$MAKE" -C "$copy" -k all other 2>&1)
            if echo "$mk_k" | grep -q 'printf "other"' && \
               echo "$make_k" | grep -q 'printf "other"'; then
                echo "ok F1 $dir"
                PASS=$((PASS + 1))
            else
                echo "FAIL: F1 $dir"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "FAIL: F1 $dir"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "FAIL: F1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# M1: missing corpus exits 2 with no-rule message
test_m1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    local copy_real
    copy_real=$(cd "$copy" && pwd -P)
    local mk_out=$("$MK" -C "$copy" 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    local make_out=$("$MAKE" -C "$copy" 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    if [ "$mk_out" = "$make_out" ]; then
        echo "ok M1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: M1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# C1: cycle corpus prints circular-dependency warning and exits 0
test_c1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    local copy_real
    copy_real=$(cd "$copy" && pwd -P)
    local mk_out=$("$MK" -C "$copy" 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    clean_copy "$copy" "$dir"
    local make_out=$("$MAKE" -C "$copy" 2>&1 | sed "s|$copy_real|DIR|g" | normalize)
    if [ "$mk_out" = "$make_out" ]; then
        echo "ok C1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: C1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# J1: wide corpus with -j 2 finishes in ~4s
test_j1() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    local start=$(date +%s%N)
    "$MK" -C "$copy" -j 2 >/dev/null 2>&1
    local end=$(date +%s%N)
    local elapsed=$(( (end - start) / 1000000 ))
    local file_count=$(cd "$copy" && ls -1 t[0-9][0-9] 2>/dev/null | wc -l)
    if [ "$file_count" -eq 40 ] && [ "$elapsed" -ge 3000 ] && [ "$elapsed" -le 6000 ]; then
        echo "ok J1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: J1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# J2: diamond with -j 4 builds all files
test_j2() {
    local copy="$1" dir="$2"
    clean_copy "$copy" "$dir"
    "$MK" -C "$copy" -j 4 >/dev/null 2>&1
    local file_count=$(cd "$copy" && ls -1 base left right 2>/dev/null | wc -l)
    if [ "$file_count" -eq 3 ]; then
        echo "ok J2 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: J2 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# R1: each refused construct exits 2 with one line on stderr
test_r1() {
    local copy="$1" dir="$2"
    local pass_all=true
    for mkfile in "$copy"/*.mk; do
        local name=$(basename "$mkfile" .mk)
        local stdout=$("$MK" -f "$mkfile" 2>/dev/null || true)
        local exit_code=0
        "$MK" -f "$mkfile" >/dev/null 2>&1 || exit_code=$?
        local stderr=$("$MK" -f "$mkfile" 2>&1 >/dev/null || true)
        if [ "$exit_code" -ne 2 ]; then
            pass_all=false
            continue
        fi
        if [ -n "$stdout" ]; then
            pass_all=false
            continue
        fi
        local line_count=$(echo "$stderr" | wc -l)
        if [ "$line_count" -ne 1 ]; then
            pass_all=false
            continue
        fi
        if ! echo "$stderr" | grep -q "$name"; then
            pass_all=false
            continue
        fi
    done
    if $pass_all; then
        echo "ok R1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: R1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# RJ: every refused construct answers the same under -j 2: mk -j 2 -f X.mk prints what
# mk -f X.mk prints, and both exit 2
test_rj() {
    local copy="$1" dir="$2"
    local pass_all=true
    for mkfile in "$copy"/*.mk; do
        local one two st1=0 st2=0
        one=$("$MK" -f "$mkfile" 2>&1 </dev/null) || st1=$?
        two=$("$MK" -j 2 -f "$mkfile" 2>&1 </dev/null) || st2=$?
        if [ "$one" != "$two" ] || [ "$st1" -ne 2 ] || [ "$st2" -ne 2 ]; then
            pass_all=false
        fi
    done
    if $pass_all; then
        echo "ok RJ $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: RJ $dir"
        FAIL=$((FAIL + 1))
    fi
}

# E1: a usage error names its problem on stderr's first line, prints nothing on
# stdout, and exits 2
test_e1() {
    local copy="$1" dir="$2"
    local pass_all=true
    local cases="-x|mk: invalid option -- x
-f|mk: option requires an argument -- f
-j 0|mk: the '-j' option requires a positive integer argument"
    while IFS='|' read -r args want; do
        local out err first st=0
        out=$(cd "$copy" && "$ROOT/mk" $args 2>/dev/null </dev/null) || st=$?
        err=$(cd "$copy" && "$ROOT/mk" $args 2>&1 >/dev/null </dev/null || true)
        first=$(printf '%s\n' "$err" | head -1)
        if [ "$st" -ne 2 ] || [ -n "$out" ] || [ "$first" != "$want" ]; then
            echo "  E1: mk $args: exit $st, first line: $first"
            pass_all=false
        fi
    done <<< "$cases"
    if $pass_all; then
        echo "ok E1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: E1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# P1: mk -p on vars matches the golden file
test_p1() {
    local copy="$1" dir="$2"
    local golden="$CORPUS_DIR/$dir/golden-p.txt"
    if [ ! -f "$golden" ]; then
        echo "FAIL: P1 $dir (golden missing)"
        FAIL=$((FAIL + 1))
        return
    fi
    local actual=$("$MK" -f "$copy/Makefile" -p 2>&1)
    local expected=$(cat "$golden")
    if [ "$actual" = "$expected" ]; then
        echo "ok P1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: P1 $dir"
        FAIL=$((FAIL + 1))
    fi
}

# Run the matrix (use a temp file to avoid subshell issues with while-read)
# same_as_make ROW DIR ARGS... — make and mk with ARGS, each in its own clean copy of DIR.
# U1 and U2 run each tool once first and compare the second run. Compared: the sorted
# output (make:/mk: read as TOOL:), the exit status, and every file left (names and bytes).
same_as_make() {
    local row="$1" dir="$2"
    shift 2
    local a b
    a=$(mktemp -d)
    b=$(mktemp -d)
    cp -R "$CORPUS_DIR/$dir/." "$a/"
    cp -R "$CORPUS_DIR/$dir/." "$b/"
    clean_copy "$a" "$dir"
    clean_copy "$b" "$dir"
    case "$row" in U1|U2|again*) ;; *) false ;; esac && {
        (cd "$a" && "$MAKE" "$@" >/dev/null 2>&1 </dev/null) || true
        (cd "$b" && "$ROOT/mk" "$@" >/dev/null 2>&1 </dev/null) || true
    }
    local make_out mk_out make_st=0 mk_st=0
    make_out=$(cd "$a" && "$MAKE" "$@" 2>&1 </dev/null) || make_st=$?
    mk_out=$(cd "$b" && "$ROOT/mk" "$@" 2>&1 </dev/null) || mk_st=$?
    # Replace each tool's own copy path with DIR so paths from different temp dirs compare equal
    # gmake prints the physical path (pwd -P), mk prints env.cwd() (also physical)
    local a_real b_real
    a_real=$(cd "$a" && pwd -P)
    b_real=$(cd "$b" && pwd -P)
    make_out=$(printf '%s\n' "$make_out" | sed "s|$a_real|DIR|g")
    mk_out=$(printf '%s\n' "$mk_out" | sed "s|$b_real|DIR|g")
    make_out=$(printf '%s\n' "$make_out" | sed -E 's/^(gmake|make):/TOOL:/' | sort)
    mk_out=$(printf '%s\n' "$mk_out" | sed -E 's/^(gmake|make|mk):/TOOL:/' | sort)
    local make_files mk_files
    make_files=$(cd "$a" && find . -type f | sort | while read -r f; do echo "$f"; cat "$f"; done | shasum)
    mk_files=$(cd "$b" && find . -type f | sort | while read -r f; do echo "$f"; cat "$f"; done | shasum)
    rm -rf "$a" "$b"
    if [ "$make_out" = "$mk_out" ] && [ "$make_st" = "$mk_st" ] && [ "$make_files" = "$mk_files" ]; then
        echo "ok $row $dir $*"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $row $dir $* (make exit $make_st, mk exit $mk_st)"
        FAIL=$((FAIL + 1))
    fi
}

# Run the matrix (use a temp file to avoid subshell issues with while-read)
MATRIX_FILE=$(mktemp)
echo "$MATRIX" > "$MATRIX_FILE"
while read -r row dir args; do
    case "$row" in
        R) set -- $args; same_as_make "$1" "$dir" "${@:2}" ;;
        *) run_test "$row" "$dir" ;;
    esac
done < "$MATRIX_FILE"
rm -f "$MATRIX_FILE"

echo ""
echo "Results: $PASS passed, $FAIL failed (expected: $EXPECTED)"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
