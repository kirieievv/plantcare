#!/usr/bin/env bash
#
# Bring firestore.indexes.json back in line with what the projects actually have.
#
# The file is generated, not written. Composite indexes get created three ways —
# by deploying this file, by `gcloud`, and by clicking the link in a "this query
# requires an index" error — and the third happens exactly when something is on
# fire and nobody is thinking about version control. Production carried an
# undeclared scheduled_test_pushes index for months that way.
#
# That matters because a deploy deletes whatever the file does not name:
# --force does it silently, and a plain deploy asks "Would you like to delete
# these indexes?", which is one keystroke away from the same result. A file that
# is never stale is the only safeguard that does not depend on somebody
# remembering. Run this, read the diff, commit it.
#
# Reads only. Nothing here deploys, creates or deletes an index.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

sync() {
  local dir="$1" project="$2"
  local file="${ROOT}/${dir}/firestore.indexes.json"

  # `firebase firestore:indexes` prints the indexes in the file's own format,
  # which is also how __name__ gets written correctly on the rare index whose
  # trailing key runs against the field before it.
  local raw
  raw="$(cd "${ROOT}/${dir}" && firebase firestore:indexes --project "${project}")"

  # The server returns entries in its own order, so writing the export straight
  # out would rewrite the whole file on every run and bury any real change in a
  # hundred lines of reshuffling. Sorting makes the diff mean something.
  python3 -c '
import json, sys
doc = json.load(sys.stdin)
key = lambda i: (i["collectionGroup"], i.get("queryScope", ""),
                 tuple((f["fieldPath"], f.get("order") or f.get("arrayConfig", ""))
                       for f in i["fields"]))
out = {"indexes": sorted(doc.get("indexes", []), key=key),
       "fieldOverrides": doc.get("fieldOverrides", [])}
sys.stdout.write(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
' <<< "${raw}" > "${file}"

  printf '%-16s %s  (%s indexes)\n' "${dir}" "${project}" \
    "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["indexes"]))' "${file}")"
}

sync plant_care     plant-care-94574
sync plant_care_dev plant-care-dev-0001

echo
if git -C "${ROOT}" diff --quiet -- '*/firestore.indexes.json'; then
  echo "No drift: both files already matched their projects."
else
  echo "Drift found — somebody created or removed an index outside the file:"
  git -C "${ROOT}" --no-pager diff --stat -- '*/firestore.indexes.json'
  echo
  echo "Read the diff, then commit it."
fi
