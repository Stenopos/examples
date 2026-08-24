#!/usr/bin/env bash
#
# check-style.sh — keep every Stenopos source in this repo formatted and lint-clean
# against a real `stenopos` binary. This is the source-hygiene gate (distinct from
# verified/verify.sh, which proves the released compiler runs the examples).
#
#   - `stenopos fmt --check` must pass for every .sten (text-based; works on files
#     that intentionally don't compile yet, e.g. `Status: designed` examples).
#   - `stenopos lint` must report no lints for every .sten that PARSES; files that
#     don't parse are skipped (their lints can't be computed).
#
# Usage:
#   STENOPOS=/path/to/stenopos ./check-style.sh   # or `stenopos` from PATH
set -uo pipefail

STENOPOS="${STENOPOS:-stenopos}"
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v "$STENOPOS" >/dev/null 2>&1 || { echo "missing: $STENOPOS" >&2; exit 2; }

mapfile -t files < <(find . -name '*.sten' | sort)
fmt_fail=0
lint_fail=0
skipped=0

echo "== stenopos fmt --check (${#files[@]} files) =="
for f in "${files[@]}"; do
  if ! "$STENOPOS" fmt --check "$f" >/dev/null 2>&1; then
    echo "  needs formatting: $f"
    fmt_fail=$((fmt_fail + 1))
  fi
done

echo "== stenopos lint =="
for f in "${files[@]}"; do
  # `compile-fail/` holds deliberately malformed programs (empty bodies, bad
  # types) that exist to be *rejected* — linting them is noise.
  case "$f" in
    */compile-fail/*) continue ;;
  esac
  # Only lint files that actually COMPILE. Aspirational "Status: designed"
  # examples use syntax that isn't implemented yet, so linting them is noise:
  # the seed's parser-based lint already skips them (its parser rejects the
  # file), but the self-host's token-based lint would process them and emit
  # spurious notes. Gating on `check` keeps both compilers consistent.
  if ! "$STENOPOS" check "$f" >/dev/null 2>&1; then
    skipped=$((skipped + 1))
    continue
  fi
  out="$("$STENOPOS" lint "$f" 2>&1)"
  if grep -q "parse errors" <<<"$out"; then
    skipped=$((skipped + 1))
    continue
  fi
  if grep -q "lint(s) found" <<<"$out"; then
    grep -vE "lint\(s\) found|No lints" <<<"$out" | sed 's/^/  /'
    lint_fail=$((lint_fail + 1))
  fi
done

echo "----"
echo "unformatted: $fmt_fail | files with lints: $lint_fail | unparseable (lint skipped): $skipped"
if [ "$fmt_fail" -eq 0 ] && [ "$lint_fail" -eq 0 ]; then
  echo "style OK"
  exit 0
fi
exit 1
