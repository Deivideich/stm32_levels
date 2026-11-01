#!/usr/bin/env bash
# Create an item. Run it FROM INSIDE the level folder:
#     cd levels/01_c_that_bites
#     ../../tools/new_item.sh 001
#
# If the item has a card (docs/items/NNN.md), its starter files are copied here and
# you are pointed to the card. Otherwise a plain skeleton is created, with the
# statement and its "Done when" copied from docs/roadmap.md into the header.
# Existing files are never overwritten.
set -euo pipefail
id="${1:?usage: new_item.sh NNN [slug_in_snake_case]}"
[[ "$id" =~ ^[0-9]{3}$ ]] || { echo "the id must have 3 digits"; exit 1; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
cards="$root/docs/items"

# ---------------------------------------------------------------- card-based item
if [ -d "$cards/$id" ]; then
  # an older plain skeleton for this item would clash with the starter (two main functions)
  for existing in ${id}_*.c; do
    [ -e "$existing" ] || continue
    if [ ! -e "$cards/$id/$existing" ]; then
      echo "ERROR: $existing is an old skeleton of item $id and would clash with the card's starter."
      echo "       If you have not started the item, remove it and retry:"
      echo "           git rm -f $existing notes/${id}.md   (or just rm)"
      exit 1
    fi
  done
  mkdir -p notes "evidence/$id"
  touch "evidence/$id/.gitkeep"
  for f in "$cards/$id"/*; do
    b="$(basename "$f")"
    if [ -e "$b" ]; then echo "kept (already exists): $b"
    else cp "$f" "$b"; echo "created: $b"; fi
  done
  if [ ! -e "notes/${id}.md" ]; then
    title="$(head -1 "$cards/$id.md" 2>/dev/null | sed 's/^# *//' || true)"
    cat > "notes/${id}.md" <<EOT
# ${title:-$id}

- Result: TODO (PASS or GAP)
- Evidence: evidence/${id}/

## Predictions (written before running)

## What I observed

## Answers to the card's questions

## What surprised me
EOT
    echo "created: notes/${id}.md"
  fi
  echo
  echo "Read the card first: docs/items/${id}.md"
  exit 0
fi

# ---------------------------------------------------------------- plain skeleton
mkdir -p notes "evidence/$id"
touch "evidence/$id/.gitkeep"

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

if compgen -G "${id}_*.c" >/dev/null; then
  echo "item $id already has a file: $(ls ${id}_*.c | head -1)"; exit 1
fi
src="${id}_${slug}.c"

cat > "$src" <<EOT
/* ${id} - ${slug}
 *
 * ${line:-(paste the statement from docs/roadmap.md here)}
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

if [ ! -e "notes/${id}.md" ]; then
  cat > "notes/${id}.md" <<EOT
# ${id} - ${slug}

- Result: TODO (PASS or GAP)
- Evidence: evidence/${id}/
- What surprised me:
EOT
fi
echo "created: $src  notes/${id}.md  evidence/${id}/"
