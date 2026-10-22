#!/bin/sh
# Publishes the current branch to the matching GitHub repository.
# Usage: publish.sh <github-owner/repo>
set -eu
target="$1"
branch="${DRONE_BRANCH:?}"
auth=$(printf 'x-access-token:%s' "${GITHUB_TOKEN:?}" | base64 | tr -d '\n')

# The CI clone may be shallow; GitHub needs the full history.
git fetch --unshallow origin 2>/dev/null || true

git -c http.extraheader="AUTHORIZATION: basic $auth" \
    push "https://github.com/$target.git" "HEAD:refs/heads/$branch"
echo "published $(git rev-parse --short HEAD) to github.com/$target ($branch)"
