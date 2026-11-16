#!/bin/sh
# Run the test suite headless in Vim and Neovim (whichever are installed).
# Set QALC_REAL=1 to use the qalc(1) in $PATH instead of the stand-in.
set -u
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
if [ "${QALC_REAL:-0}" != 1 ]; then
  PATH="$root/test/bin:$PATH"
  export PATH
fi
status=0
for editor in ${EDITORS:-vim nvim}; do
  command -v "$editor" >/dev/null 2>&1 || { echo "skip: $editor not found"; continue; }
  log=$(mktemp)
  export QALC_TEST_LOG="$log"
  if [ "$editor" = nvim ]; then
    nvim --clean --headless -i NONE -n -S test/test.vim >/dev/null 2>&1
  else
    vim -Nu NONE -i NONE -n -es -S test/test.vim >/dev/null 2>&1
  fi
  [ -s "$log" ] || echo "FAIL: $editor produced no results" >"$log"
  sed "s/^/$editor: /" "$log"
  grep -q '^FAIL' "$log" && status=1
  rm -f "$log"
done
exit $status
