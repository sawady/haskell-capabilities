#!/usr/bin/env bash
# Builds and runs each example in src/, checks that the ones in must-fail/ do
# not compile, and saves everything that is shown to outputs/.
#
# By default it uses the `ghc` on the PATH (or GHCup's). To try another version:
#   GHC=ghc-9.6.7 ./build.sh
# Exits with the number of failures: 0 if everything went as expected.
set -uo pipefail
cd "$(dirname "$0")"
command -v "${GHC:-ghc}" > /dev/null || export PATH="$HOME/.ghcup/bin:$PATH"
ghc="${GHC:-ghc}"
version=$("$ghc" --numeric-version) || { echo "Cannot find $ghc"; exit 1; }
build="build/$version"
GHCC="$ghc -Wall -isrc -outputdir $build"
mkdir -p "$build" outputs
failures=0

# The examples run with a fixed environment so that the outputs are
# reproducible: A_TypesOnly counts the environment variables (it always sees
# two), and LANG keeps the output encoding predictable.
fixed_env=(env -i "LANG=${LC_ALL:-${LANG:-C.UTF-8}}" PATH=/usr/bin:/bin)

"$ghc" --version > outputs/ghc-version.txt

for f in src/[A-Z]*_*.hs; do
  n=$(basename "$f" .hs)
  if $GHCC -o "$build/$n" "$f" > "$build/$n.log" 2>&1; then
    if "${fixed_env[@]}" "./$build/$n" > "outputs/$n.txt" 2>&1; then
      echo "ok                $n"
    else
      cat "outputs/$n.txt"; echo "FAILED TO RUN $n"; failures=$((failures + 1))
    fi
  else
    cat "$build/$n.log"; echo "DOES NOT COMPILE $n"; failures=$((failures + 1))
  fi
done

for f in must-fail/*.hs; do
  n=$(basename "$f" .hs)
  if $GHCC -v0 -fno-code "$f" > "outputs/must-fail-$n.txt" 2>&1; then
    echo "COMPILED (should have failed) $n"; failures=$((failures + 1))
  else
    echo "fails as expected $n"
  fi
done

# The types GHC infers for the functions without signatures in example B
if ! $GHCC -v0 -Wno-missing-signatures -e ':t summary' -e ':t summaryWithFile' \
    src/B_TaglessFinal.hs > outputs/B_inferred-types.txt 2>&1; then
  cat outputs/B_inferred-types.txt; echo "FAILED ghc -e (inferred types of B)"; failures=$((failures + 1))
fi

# GHCi sessions shown in "Exploring in GHCi" (README and page). Each step runs
# its commands in a fresh GHCi and appends them to the transcript, after a
# "ghci> " prompt, followed by what GHC answers.
ghci_step() {
  local out=$1 file=$2 c
  shift 2
  local args=()
  for c in "$@"; do printf 'ghci> %s\n' "$c" >> "$out"; args+=(-e "$c"); done
  if ! $GHCC -v0 -Wno-missing-signatures "${args[@]}" "$file" >> "$out" 2>&1; then
    cat "$out"; echo "FAILED GHCi session $out"; failures=$((failures + 1))
  fi
}

: > outputs/ghci-B.txt
ghci_step outputs/ghci-B.txt src/B_TaglessFinal.hs ':info Files'
ghci_step outputs/ghci-B.txt src/B_TaglessFinal.hs \
  'runState (runTest (summary "https://example.org")) []'
ghci_step outputs/ghci-B.txt src/B_TaglessFinal.hs \
  'let quiet url = do { page <- httpGet url; return (firstLine page) }' ':t quiet'
ghci_step outputs/ghci-B.txt src/B_TaglessFinal.hs \
  'let both url path = do { page <- httpGet url; note <- readTextFile path; printLine (page ++ note) }' ':t both'

: > outputs/ghci-D.txt
ghci_step outputs/ghci-D.txt src/D_EffectRows.hs ':t summary'
ghci_step outputs/ghci-D.txt src/D_EffectRows.hs ':t handleNet fakePages (summary "https://example.org")'
ghci_step outputs/ghci-D.txt src/D_EffectRows.hs \
  ':t handleConsolePure (handleNet fakePages (summary "https://example.org"))'
ghci_step outputs/ghci-D.txt src/D_EffectRows.hs \
  'run (handleConsolePure (handleNet fakePages (summary "https://example.org")))'

exit $failures
