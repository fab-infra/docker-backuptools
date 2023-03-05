#!/bin/bash
#
# Amazon S3 (or compatible) backup backend
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
BACKUP_S3_BUCKET="${BACKUP_S3_BUCKET:-backups}"
BACKUP_S3_REMOTE="${BACKUP_S3_REMOTE:-s3}"
BACKUP_S3_PROVIDER="${BACKUP_S3_PROVIDER:-AWS}"
BACKUP_S3_REGION="${BACKUP_S3_REGION:-eu-west-3}"
BACKUP_S3_S3CMD_OPTS="${BACKUP_S3_S3CMD_OPTS:---acl-private}"

# Check backend
function backup_check
{
	if [ -z "$BACKUP_S3_BUCKET" ]; then
		echo "S3 backup bucket must be specified (BACKUP_S3_BUCKET environment variable)"
		return 1
	fi
	if [ -z "$BACKUP_S3_PROVIDER" ]; then
		echo "S3 backup provider must be specified (BACKUP_S3_PROVIDER environment variable)"
		return 1
	fi
	if [ -z "$BACKUP_S3_REGION" ]; then
		echo "S3 backup region must be specified (BACKUP_S3_REGION environment variable)"
		return 1
	fi
	if ! command -v s3cmd > /dev/null 2>&1; then
		echo "S3 client (s3cmd) is missing, please install it first"
		return 1
	fi
	if [ "${BACKUP_S3_PROVIDER^^}" = "OVH" ]; then
		BACKUP_S3_S3CMD_OPTS="${BACKUP_S3_S3CMD_OPTS} --host 's3.${BACKUP_S3_REGION,,}.io.cloud.ovh.net' --host-bucket '%(bucket).s3.${BACKUP_S3_REGION,,}.io.cloud.ovh.net'"
		export RCLONE_S3_ENDPOINT="s3.${BACKUP_S3_REGION,,}.io.cloud.ovh.net"
		export RCLONE_S3_PROVIDER="other"
	else
		export RCLONE_S3_PROVIDER="$BACKUP_S3_PROVIDER"
	fi
	BACKUP_S3_S3CMD_OPTS="${BACKUP_S3_S3CMD_OPTS} --region=${BACKUP_S3_REGION,,}"
	export RCLONE_S3_REGION="$BACKUP_S3_REGION"
	return 0
}

# List backup files
function backup_list
{
	local SUBDIR="$1"
	s3cmd $BACKUP_S3_S3CMD_OPTS ls -r "s3://$BACKUP_S3_BUCKET/$SUBDIR/" | sed "s#.*s3://$BACKUP_S3_BUCKET/$SUBDIR/##g"
}

# Save a backup
function backup_save
{
	local SUBDIR="$1"
	local FILE="$2"
	local LINK="$3"
	local FILE_NAME=`basename "$FILE"`
	local RET=0
	echo "Saving 's3://$BACKUP_S3_BUCKET/$SUBDIR/$FILE_NAME'..."
	s3cmd -q $BACKUP_S3_S3CMD_OPTS put "$FILE" "s3://$BACKUP_S3_BUCKET/$SUBDIR/"
	RET=$?
	if [ $RET -eq 0 -a -n "$LINK" ]; then
		echo "Creating copy 's3://$BACKUP_S3_BUCKET/$SUBDIR/$LINK'..."
		s3cmd -q $BACKUP_S3_S3CMD_OPTS cp "s3://$BACKUP_S3_BUCKET/$SUBDIR/$FILE_NAME" "s3://$BACKUP_S3_BUCKET/$SUBDIR/$LINK"
		RET=$?
	fi
	return $RET
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	echo "Deleting 's3://$BACKUP_S3_BUCKET/$SUBDIR/$FILE_NAME'..."
	s3cmd -q $BACKUP_S3_S3CMD_OPTS del "s3://$BACKUP_S3_BUCKET/$SUBDIR/$FILE_NAME"
}

# Prune outdated backups
function backup_prune
{
	local SUBDIR="$1"
	local FILE_NAME_REGEX="$2"
	local MAX_BACKUPS="$3"
	local NUMBER=1
	echo "Pruning backups in 's3://$BACKUP_S3_BUCKET/$SUBDIR/'... (max: $MAX_BACKUPS)"
	backup_list "$SUBDIR" | grep "$FILE_NAME_REGEX" | sort -r | while read BACKUPFILE; do
		if [ "$NUMBER" -gt "$MAX_BACKUPS" ]; then
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
	echo "Syncing '$SRC_DIR' to 's3://$BACKUP_S3_BUCKET/$SUBDIR/'..."
	rclone sync $DEF_OPTS $EXT_OPTS "$SRC_DIR/" "$BACKUP_S3_REMOTE:$BACKUP_S3_BUCKET/$SUBDIR/"
}
