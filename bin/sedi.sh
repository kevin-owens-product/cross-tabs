#!/usr/bin/env bash
# sed -i compatible with both Linux and macOS
# https://stackoverflow.com/a/38595160/403702
sed --version > /dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
