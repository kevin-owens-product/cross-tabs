#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="${1}"
NEW_VERSION="${2}"

if [ $# -ne 2 ]; then
    echo "Usage: $0 AUTHOR/PKG NEW_VERSION"
    exit 1
fi

if [[ "${OSTYPE}" == "linux-gnu"* ]]; then

    git ls-files '*elm.json' \
        | xargs sed -i "s_${PACKAGE_NAME}....[0-9.]*_${PACKAGE_NAME}\": \"${NEW_VERSION}_"

elif [[ "${OSTYPE}" == "darwin"* ]]; then

    git ls-files '*elm.json' \
        | xargs sed -i '' -e "s_${PACKAGE_NAME}....[0-9.]*_${PACKAGE_NAME}\": \"${NEW_VERSION}_"

else
    echo "Unsupported OS: ${OSTYPE}"
    echo "Please complain on our Slack :P"
fi
