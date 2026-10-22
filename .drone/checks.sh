#!/bin/sh
# Repository checks run by Drone on every push, pull request and tag.
set -eu

before="${DRONE_COMMIT_BEFORE:-}"
if [ -n "$before" ] && git cat-file -e "$before^{commit}" 2>/dev/null; then
    range="$before..HEAD"
else
    range="HEAD"
fi
echo "checking commits: $range"

status=0
for c in $(git rev-list --no-merges "$range"); do
    if ! git log -1 --format=%B "$c" | grep -q '^Signed-off-by: '; then
        echo "FAIL $c: missing DCO sign-off (commit with: git commit -s)"
        status=1
    fi
done
[ "$status" -eq 0 ] && echo "all checks passed"
exit "$status"
