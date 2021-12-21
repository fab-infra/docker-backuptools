#!/bin/bash
#
# Google Cloud Storage backup backend
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_GCS_SA_FILE="${BACKUP_GCS_SA_FILE:-$BACKUP_DIR/backup-sa.json}"
BACKUP_GCS_REMOTE="${BACKUP_GCS_REMOTE:-gcs}"
BACKUP_GCS_GSUTIL_OPTS="-q -o Credentials:gs_service_key_file=$BACKUP_GCS_SA_FILE"

# Check backend
function backup_check
{
	if [ ! -e "$BACKUP_GCS_SA_FILE" ]; then
		echo "GCS Service Account file '$BACKUP_GCS_SA_FILE' does not exist (BACKUP_GCS_SA_FILE environment variable)"
		return 1
	fi
	if [ -z "$BACKUP_GCS_BUCKET" ]; then
		echo "GCS backup bucket must be specified (BACKUP_GCS_BUCKET environment variable)"
		return 1
	fi
	if ! command -v gsutil > /dev/null 2>&1; then
		echo "GCS client (gsutil) is missing, please install it first"
		return 1
	fi
	return 0
}

# List backup files
function backup_list
{
	local SUBDIR="$1"
	gsutil $BACKUP_GCS_GSUTIL_OPTS ls -r "gs://$BACKUP_GCS_BUCKET/$SUBDIR/**" | sed "s#gs://$BACKUP_GCS_BUCKET/$SUBDIR/##g"
}

# Save a backup
function backup_save
{
	local SUBDIR="$1"
	local FILE="$2"
	gsutil $BACKUP_GCS_GSUTIL_OPTS cp "$FILE" "gs://$BACKUP_GCS_BUCKET/$SUBDIR/"
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	gsutil $BACKUP_GCS_GSUTIL_OPTS rm "gs://$BACKUP_GCS_BUCKET/$SUBDIR/$FILE_NAME"
}

# Prune outdated backups
function backup_prune
{
	local SUBDIR="$1"
	local FILE_NAME_REGEX="$2"
	local MAX_BACKUPS="$3"
	local NUMBER=1
	backup_list "$SUBDIR" | grep "$FILE_NAME_REGEX" | sort -r | while read BACKUPFILE; do
		if [ "$NUMBER" -gt "$MAX_BACKUPS" ] ; then
			echo "Removing backup file $BACKUPFILE"
			backup_delete "$SUBDIR" "$BACKUPFILE"
		fi
		NUMBER=`expr $NUMBER + 1`
	done
}

# Sync files
function backup_sync
{
	local SUBDIR="$1"
	local SRC_DIR="$2"
	local EXT_OPTS="${@:3}"
	local DEF_OPTS="--fast-list --links --delete-excluded --ignore-errors -v"
	if [ -e "$SRC_DIR/backup.filter" ]; then
		DEF_OPTS="$DEF_OPTS --filter-from=$SRC_DIR/backup.filter"
	fi
	rclone sync $DEF_OPTS $EXT_OPTS "$SRC_DIR/" "$BACKUP_GCS_REMOTE:$BACKUP_GCS_BUCKET/$SUBDIR/"
}
