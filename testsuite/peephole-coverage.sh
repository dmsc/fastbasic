#!/bin/sh
#
# Report peephole optimizer rule coverage from the test suite.
#
# The compiler prints every rule and every successful match when
# FASTBASIC_PEEPHOLE_DEBUG is set.  Compile the test sources with both
# targets, collect the matches, and fail if any rule was not reached.
#
set -eu

cd "$(dirname "$0")/.."

compiler=build/bin/fastbasic
[ -x "$compiler" ] || {
    echo "peephole-coverage: build/bin/fastbasic not found; run make first" >&2
    exit 2
}

out=build/peephole-coverage
rm -rf "$out"
mkdir -p "$out"
log=$out/debug.log
: > "$log"

for src in testsuite/tests/*.bas; do
    [ -f "$src" ] || continue
    name=$(basename "$src" .bas)
    for target in atari-int atari-fp; do
        FASTBASIC_PEEPHOLE_DEBUG=1 \
            "$compiler" -target-path:compiler -syntax-path:src/syntax \
            -t:"$target" -c -o "$out/$name.$target.asm" "$src" \
            2>>"$log" >/dev/null || true
    done
done

# Keep the table name and rule number with the pattern: the same source
# pattern can occur in more than one phase, or with different guards in the
# same phase.
sed -n 's/^peephole pattern \[\([^]]*\)\] #\([0-9]*\): /\1|\2|/p' "$log" | sort -u > "$out/patterns"
sed -n 's/^peephole match \[\([^]]*\)\] #\([0-9]*\): /\1|\2|/p' "$log" | sort -u > "$out/matches"
sed -n 's/^peephole apply \[\([^]]*\)\] #\([0-9]*\): /\1|\2|/p' "$log" | sort -u > "$out/applied"

comm -23 "$out/patterns" "$out/matches" > "$out/missing"

patterns=$(wc -l < "$out/patterns")
matches=$(wc -l < "$out/matches")
applied=$(wc -l < "$out/applied")
printf 'Peephole coverage: %s/%s rules matched, %s rewrites\n' \
       "$matches" "$patterns" "$applied"

if [ -s "$out/missing" ]; then
    echo "Rules not reached:"
    awk -F'|' '{print "  [" $1 "] #" $2 ": " $3}' "$out/missing"
    echo "Debug log: $log"
    exit 1
fi
