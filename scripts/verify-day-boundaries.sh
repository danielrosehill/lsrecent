#!/usr/bin/env bash
#
# Check lsrecent's fork-free midnight arithmetic against `date`, for every day of
# a year in several timezones.
#
# The binary computes local midnights with bash's own printf rather than forking
# `date`, because bare `ls` goes through that path — and the buckets are only
# honest if those boundaries are exact. The hard case is a DST week: a naive
# `midnight - 86400 * k` lands an hour off for every day after a transition, and
# with a bucket per day that is six wrong boundaries from one bad assumption.
# day_midnights therefore walks one snapped day at a time; this is the proof.
#
# Slow (~3 minutes) — it is one `date` fork per boundary, which is the point:
# the reference has to be an independent implementation, not the one under test.
# Run it after touching snap_midnight or day_midnights.
#
#   scripts/verify-day-boundaries.sh [year]
#
# America/Santiago and friends are deliberately absent: they transition *at*
# midnight, so local midnight either does not exist or happens twice and `date`
# has no single right answer to compare against. The binary lands within the hour
# there, which is well inside what recency bucketing cares about.

set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
YEAR=${1:-2026}

# Pull the two functions out of the binary rather than sourcing it, which would
# run the dispatch at the bottom.
eval "$(awk '/^snap_midnight\(\)/,/^}/' "$HERE/lsrecent")"
eval "$(awk '/^day_midnights\(\)/,/^}/' "$HERE/lsrecent")"
declare -a day_mid=()

zones=(Asia/Jerusalem America/New_York Australia/Sydney Australia/Lord_Howe
       Pacific/Chatham Europe/Dublin Asia/Kolkata UTC)

fail=0 checked=0
for tz in "${zones[@]}"; do
    export TZ=$tz
    days=$(date -d "$YEAR-12-31" +%j)
    for (( d = 0; d < days; d++ )); do
        day=$(date -d "$YEAR-01-01 +$d days" +%Y-%m-%d)
        day_midnights "$(date -d "$day 00:00:00" +%s)"
        for k in 0 1 2 3 4 5 6 7; do
            want=$(date -d "$day -$k days 00:00:00" +%s)
            (( checked++ ))
            [[ "${day_mid[k]}" == "$want" ]] && continue
            echo "MISMATCH $tz $day -${k}d: got ${day_mid[k]}, want $want" >&2
            (( ++fail > 20 )) && { echo "too many; stopping" >&2; exit 1; }
        done
    done
done

echo "checked $checked boundaries in ${#zones[@]} zones, $fail mismatches"
(( fail == 0 ))
