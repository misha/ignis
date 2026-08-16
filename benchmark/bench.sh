#!/usr/bin/env bash
#
# Runs Ignis benchmarks.
#
#   ./bench.sh                        every benchmark, under `flutter test`
#   ./bench.sh update update_count    just those, under `flutter test`
#   ./bench.sh -p update              under the VM's CPU sampling profiler
#   ./bench.sh -r update              compiled to a release binary, then run
#   ./bench.sh -r flame_update        the Flame comparison, same way
#
# A name resolves to `<name>_benchmark.dart`, or to the same under `flame/`,
# so `update` and `flame_update` both work.
set -euo pipefail
cd "$(dirname "$0")"

mode=test

while getopts ':tpr' option; do
  case "$option" in
    t) mode=test ;;
    p) mode=profile ;;
    r) mode=release ;;
    *) echo "usage: $(basename "$0") [-t|-p|-r] [benchmark...]" >&2; exit 2 ;;
  esac
done

shift $((OPTIND - 1))

resolve() {
  local name="$1"

  for candidate in "$name" "${name}_benchmark.dart" "flame/${name}_benchmark.dart"; do
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return
    fi
  done

  echo "no such benchmark: $name" >&2
  exit 1
}

if [ "$#" -eq 0 ]; then
  targets=(*_benchmark.dart flame/*_benchmark.dart)
else
  targets=()
  for name in "$@"; do
    targets+=("$(resolve "$name")")
  done
fi

for target in "${targets[@]}"; do
  case "$mode" in
    test)
      flutter test "$target"
      ;;
    profile)
      PROFILE=1 flutter test --enable-vmservice "$target"
      ;;
    release)
      flutter build linux --release -t "$target"
      ./build/linux/*/release/bundle/benchmark
      ;;
  esac
done
