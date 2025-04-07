#!/usr/bin/env bash

# Git revision
if [ -z "$GITHUB_SHA" ]; then
    git_rev="$(git rev-parse --verify HEAD)"
else
    git_rev=$GITHUB_SHA
fi

# revision code
revision=$git_rev

echo "${revision}"
