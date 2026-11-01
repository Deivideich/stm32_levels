#!/usr/bin/env bash
# Progress per level, from docs/roadmap.md and the notes/NNN.md files.
# An item counts as done when its note has a line starting with "- Result: PASS",
# and as a gap when it starts with "- Result: GAP".
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
[ -f "$road" ] || { echo "missing docs/roadmap.md"; exit 1; }

declare -A pass gap
for f in "$root"/levels/*/notes/[0-9][0-9][0-9].md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" .md)"
  if   grep -qE '^- Result: PASS' "$f"; then pass[$id]=1
  elif grep -qE '^- Result: GAP'  "$f"; then gap[$id]=1; fi
done

declare -A total done_ gaps title
order=(); lvl=""; next=""; all=0; ok=0
while IFS= read -r line; do
  if [[ $line =~ ^###\ Level\ ([0-9]+)\  ]]; then
    lvl="${BASH_REMATCH[1]}"; title[$lvl]="${line#*— }"; order+=("$lvl")
  elif [[ -n $lvl && $line =~ ^-\ \*\*([0-9]{3})\*\* ]]; then
    id="${BASH_REMATCH[1]}"
    total[$lvl]=$(( ${total[$lvl]:-0} + 1 )); all=$((all+1))
    if   [[ -n ${pass[$id]:-} ]]; then done_[$lvl]=$(( ${done_[$lvl]:-0} + 1 )); ok=$((ok+1))
    elif [[ -n ${gap[$id]:-}  ]]; then gaps[$lvl]=$(( ${gaps[$lvl]:-0} + 1 ))
    fi
    [[ -z $next && -z ${pass[$id]:-} ]] && next="$id"
  elif [[ $line =~ ^##\  ]]; then lvl=""
  fi
done < "$road"

printf '%-5s %-44s %9s %5s\n' Level Title Done Gaps
for l in "${order[@]}"; do
  printf '%-5s %-44.44s %4s/%-4s %5s\n' "$l" "${title[$l]}" "${done_[$l]:-0}" "${total[$l]}" "${gaps[$l]:-0}"
done
echo
printf 'Total: %d/%d items PASS (%d%%)\n' "$ok" "$all" $(( all ? ok*100/all : 0 ))
[ -n "$next" ] && { echo -n "Next: "; grep -m1 "^- \*\*${next}\*\*" "$road" | sed -E 's/^- \*\*([0-9]+)\*\* /\1 /' | cut -c1-110; }
exit 0
