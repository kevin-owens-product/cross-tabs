#!/usr/bin/env bash

if [ -z "$NOT_MERGED_BRANCHES" ]; then
    git ls-remote --heads origin | grep -Eo "refs/heads/.*" | sed 's/refs\/heads\///g' | paste -sd "," -
else
    echo $NOT_MERGED_BRANCHES
fi
