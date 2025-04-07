#!/bin/bash

# You need https://github.com/sharkdp/fd for this script.

for directory in $(fd --glob '**/elm.json' --format '{//}'); do
    cd "$directory" || exit
    elm-json upgrade --unsafe --yes
    cd - || exit
done
