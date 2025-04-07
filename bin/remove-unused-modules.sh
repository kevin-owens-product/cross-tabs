#!/bin/bash

npx elm-review client/ --template jfmengels/elm-review-unused/example --rules NoUnused.Exports --extract --report=json \
    | jq -r '.errors[] | select(.errors[].details[] | contains("This module is never used")) | .path' \
    | xargs -I {} sh -c 'echo "Removing: {}"; rm -f {}'