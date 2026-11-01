#!/usr/bin/env bash
# Create a level folder from the roadmap.   Run from the repo root:
#     tools/new_level.sh 1                 # -> levels/01_c_that_bites/
#     tools/new_level.sh 1 c_that_bites    # your own folder name
# It writes the level Makefile and a README with the prerequisite line and the item range.
set -euo pipefail
n="${1:?usage: new_level.sh LEVEL_NUMBER [folder_name]}"
[[ "$n" =~ ^[0-9]+$ ]] || { echo "level must be a number"; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
[ -f "$road" ] || { echo "missing docs/roadmap.md"; exit 1; }

head_line="$(grep -m1 -E "^### Level ${n} " "$road" || true)"
[ -n "$head_line" ] || { echo "Level $n is not in the roadmap"; exit 1; }
title="${head_line#*— }"

name="${2:-}"
if [ -z "$name" ]; then
  name="$(echo "$title" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/ /g' \
    | awk 'BEGIN{split("a an and the in of to from on for with",w," ");for(k in w)stop[w[k]]=1}
           {n=0;out="";for(i=1;i<=NF&&n<3;i++){if($i in stop)continue;out=out (n?"_":"") $i;n++}print out}')"
fi
dir="$root/levels/$(printf '%02d' "$n")_${name}"
existing="$(ls -d "$root"/levels/"$(printf '%02d' "$n")"_* 2>/dev/null | head -1 || true)"
[ -z "$existing" ] || { echo "already exists: ${existing#$root/}"; exit 0; }

# prerequisite line = the line right after the heading
prereq="$(awk -v h="$head_line" '$0==h{f=1;next} f&&NF{print;exit}' "$road")"
first="$(awk -v h="$head_line" '$0==h{f=1;next} f&&/^- \*\*[0-9]{3}\*\*/{match($0,/[0-9]{3}/);print substr($0,RSTART,3);exit}' "$road")"
last="$(awk -v h="$head_line" '$0==h{f=1;next} f&&/^(### |## )/{exit} f&&/^- \*\*[0-9]{3}\*\*/{match($0,/[0-9]{3}/);l=substr($0,RSTART,3)} END{print l}' "$road")"

mkdir -p "$dir"
if [ "$n" -le 2 ]; then mk=host.mk; else mk=target.mk; fi
echo "include ../../mk/$mk" > "$dir/Makefile"
cat > "$dir/README.md" <<EOT
# Level $n - $title

$prereq

Items ${first}-${last}. The statements and their "Done when" live in
[docs/roadmap.md](../../docs/roadmap.md).

Create an item skeleton with:

    ../../tools/new_item.sh ${first}
EOT
[ "$n" -le 2 ] || echo "note: mk/target.mk is added when you reach Level 3 (board builds)."
echo "created: ${dir#$root/}"
