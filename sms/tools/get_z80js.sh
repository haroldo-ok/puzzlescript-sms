#!/bin/sh
# Fetch the MIT-licensed Z80 core (DrGoldfire/Z80.js) used by tools/smsrun.js
set -e
cd "$(dirname "$0")"
curl -sL https://raw.githubusercontent.com/DrGoldfire/Z80.js/master/Z80.js -o Z80.js
printf '\nif (typeof module !== "undefined") module.exports = Z80;\n' >> Z80.js
echo "Z80.js downloaded."
