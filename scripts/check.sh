#!/bin/sh
# Compiles and runs every example and checks its output.
#
#   STENOPOS=/path/to/stenopos sh scripts/check.sh [path ...]
#
# For each <name>.sten:
#   - under errors/ or a compile-fail/ directory, `stenopos check` must reject
#     it, and its diagnostics must contain the text of <name>.expected;
#   - otherwise it is built and run from its own directory, with the
#     arguments in <name>.args (if any); its stdout must equal <name>.expected
#     and its exit code <name>.exitcode (default 0).
# Files listed in scripts/quarantine.txt are skipped or only built.
# With VALGRIND=1, each program that passes is run again under valgrind and
# must not leak or touch memory it doesn't own (CI runs it this way).
# Builds run one at a time. Exits non-zero on any failure.
set -u

STENOPOS="${STENOPOS:-stenopos}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUARANTINE="$ROOT/scripts/quarantine.txt"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stenopos-examples.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT INT TERM

if ! command -v "$STENOPOS" >/dev/null 2>&1; then
    echo "check.sh: compiler not found: $STENOPOS (set STENOPOS)" >&2
    exit 2
fi
TIMEOUT=""
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT="timeout 120"
fi

pass=0
fail=0
skipped=0
failed=""

quarantine_mode() {
    awk -v p="$1" '$1 !~ /^#/ && $2 == p { print $1; exit }' "$QUARANTINE"
}

report_fail() {
    echo "FAIL  $1: $2"
    fail=$((fail + 1))
    failed="$failed $1"
}

check_compile_fail() {
    rel="$1"
    want="${rel%.sten}.expected"
    if [ ! -f "$want" ]; then
        report_fail "$rel" "no .expected diagnostic"
        return
    fi
    if "$STENOPOS" check "$rel" >"$TMP/out" 2>&1; then
        report_fail "$rel" "compiled, but must be rejected"
    elif grep -qF -- "$(cat "$want")" "$TMP/out"; then
        echo "ok    $rel (rejected)"
        pass=$((pass + 1))
    else
        report_fail "$rel" "rejected without '$(cat "$want")':"
        sed 's/^/        /' "$TMP/out" | head -5
    fi
}

check_run() {
    rel="$1"
    mode="$2"
    base="${rel%.sten}"
    rm -f "$TMP/bin"
    if ! "$STENOPOS" build "$rel" "$TMP/bin" >"$TMP/build" 2>&1; then
        report_fail "$rel" "does not build:"
        sed 's/^/        /' "$TMP/build" | head -5
        return
    fi
    if [ "$mode" = build ]; then
        echo "ok    $rel (built only: quarantined)"
        pass=$((pass + 1))
        return
    fi
    if [ ! -f "$base.expected" ]; then
        report_fail "$rel" "no .expected output"
        return
    fi
    want_code=0
    if [ -f "$base.exitcode" ]; then
        want_code="$(tr -d '[:space:]' <"$base.exitcode")"
    fi
    args=""
    if [ -f "$base.args" ]; then
        args="$(cat "$base.args")"
    fi
    # shellcheck disable=SC2086 # .args is split into words on purpose
    (cd "$(dirname "$rel")" && $TIMEOUT "$TMP/bin" $args) \
        <"/dev/null" >"$TMP/stdout" 2>"$TMP/stderr"
    code=$?
    if ! cmp -s "$TMP/stdout" "$base.expected"; then
        report_fail "$rel" "output differs from $base.expected:"
        diff "$base.expected" "$TMP/stdout" | head -10 | sed 's/^/        /'
    elif [ "$code" != "$want_code" ]; then
        report_fail "$rel" "exit code $code, expected $want_code"
        head -5 "$TMP/stderr" | sed 's/^/        /'
    elif [ "${VALGRIND:-}" = 1 ] && ! memcheck "$rel" "$args"; then
        report_fail "$rel" "valgrind found a leak or a memory error:"
        grep -E "definitely lost|indirectly lost|Invalid (read|write|free)|ERROR SUMMARY" "$TMP/vg" | head -6 | sed 's/^/        /'
    else
        echo "ok    $rel"
        pass=$((pass + 1))
    fi
}

# memcheck REL ARGS: run the built program under valgrind (0 when clean).
memcheck() {
    # shellcheck disable=SC2086 # ARGS is split into words on purpose
    (cd "$(dirname "$1")" && ulimit -s unlimited 2>/dev/null
     timeout 600 valgrind --leak-check=full --error-exitcode=99 "$TMP/bin" $2) \
        <"/dev/null" >/dev/null 2>"$TMP/vg"
    rc=$?
    [ "$rc" -ne 99 ] && [ "$rc" -ne 124 ]
}

cd "$ROOT" || exit 2
if [ "$#" -gt 0 ]; then
    files="$*"
else
    files="$(find . -name '*.sten' -not -path './.git/*' | sed 's|^\./||' | sort)"
fi

for rel in $files; do
    mode="$(quarantine_mode "$rel")"
    if [ "$mode" = skip ]; then
        echo "skip  $rel (quarantined)"
        skipped=$((skipped + 1))
        continue
    fi
    case "$rel" in
        errors/* | */compile-fail/*) check_compile_fail "$rel" ;;
        *) check_run "$rel" "$mode" ;;
    esac
done

echo "----"
echo "$pass passed, $fail failed, $skipped quarantined"
if [ "$fail" -ne 0 ]; then
    echo "failed:$failed"
    exit 1
fi
exit 0
