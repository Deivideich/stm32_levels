#!/usr/bin/env bash
# Create an item skeleton. Run it FROM INSIDE the level folder:
#     cd levels/01_c_that_bites_in
#     ../../tools/new_item.sh 001                  # slug taken from the statement
#     ../../tools/new_item.sh 001 static_state     # or your own slug
# The statement and its "Done when" are copied from docs/roadmap_v4.md into the .c header.
set -euo pipefail
id="${1:?usage: new_item.sh NNN [slug_in_snake_case]}"
[[ "$id" =~ ^[0-9]{3}$ ]] || { echo "the id must have 3 digits"; exit 1; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap_v4.md"

line=""
if [ -f "$road" ]; then
  line="$(grep -m1 "^- \*\*${id}\*\*" "$road" | sed -E 's/^- \*\*[0-9]+\*\* //; s#\*/#* /#g' || true)"
fi

slug="${2:-}"
if [ -z "$slug" ]; then
  [ -n "$line" ] || { echo "item $id is not in the roadmap; pass a slug"; exit 1; }
  slug="$(echo "$line" \
    | sed -E 's/^(`[A-Z]`( ◈)?|`L` \*\*Block:\*\*( ◈)?) //; s/ — \*Done when:\*.*$//' \
    | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/ /g' \
    | awk '{for(i=1;i<=4&&i<=NF;i++) printf "%s%s", $i, (i<4&&i<NF?"_":"")}')"
fi
[[ "$slug" =~ ^[a-z0-9_]+$ ]] || { echo "the slug uses lowercase letters, digits and _"; exit 1; }

src="${id}_${slug}.c"
[ -e "$src" ] && { echo "$src already exists"; exit 1; }
ls ${id}_*.c >/dev/null 2>&1 && { echo "item $id already has a file: $(ls ${id}_*.c | head -1)"; exit 1; }

mkdir -p notes "evidence/$id"
touch "evidence/$id/.gitkeep"
cat > "$src" <<EOT
/* ${id} - ${slug}
 *
 * ${line:-(paste the statement from docs/roadmap_v4.md here)}
 *
 * Result: PASS / GAP   (one line on why)
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int main(void)
{
    /* TODO: your solution, and the asserts that prove "Done when". */
    assert(0 && "item not solved yet");
    return 0;
}
EOT

cat > "notes/${id}.md" <<EOT
# ${id} - ${slug}

- Result: TODO (PASS or GAP)
- Evidence: evidence/${id}/
- What surprised me:
EOT
echo "created: $src  notes/${id}.md  evidence/${id}/"
