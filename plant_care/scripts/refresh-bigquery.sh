#!/usr/bin/env bash
# Refreshes the BigQuery copy of Firestore.
#
# Exports the whole database to GCS, then reloads every table. Both steps
# replace what was there, so running it twice is the same as running it once.
# Firestore is only read; the managed export does not touch the live database.
#
#   ./scripts/refresh-bigquery.sh
#
# Takes a couple of minutes at present size. Requires gcloud logged in as
# someone who can export Firestore and write BigQuery.

set -euo pipefail

PROJECT=plant-care-94574
BUCKET=gs://plant-care-94574-firestore-exports
DATASET=botanly
STAMP=$(date -u +%Y%m%d-%H%M%S)
PREFIX="${BUCKET}/snapshot-${STAMP}"

# Everything except the collections that carry live password-reset PINs and the
# emails containing them. Those stay in Firestore: a copy in a warehouse several
# agents read is a way to sign in as anybody.
KINDS="users plants tasks health_checks watering_events ai_usage ai_usage_daily push_notifications seasonal_tips fcm_tokens facts memory plant_chats messages chat_quotas"

echo "→ exporting to ${PREFIX}"
gcloud firestore export "$PREFIX" \
  --project "$PROJECT" \
  --collection-ids="$(echo "$KINDS" | tr ' ' ',')" >/dev/null

echo "→ loading into ${DATASET}"
for k in $KINDS; do
  bq --project_id="$PROJECT" --location=europe-west3 load \
     --replace --source_format=DATASTORE_BACKUP \
     "${DATASET}.${k}" \
     "${PREFIX}/all_namespaces/kind_${k}/all_namespaces_kind_${k}.export_metadata" \
     >/dev/null 2>&1 && echo "   ✓ $k" || echo "   ✗ $k"
done

echo "→ done. Snapshots older than 30 days are deleted by the bucket itself."
