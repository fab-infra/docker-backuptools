#!/bin/bash
#
# Backup Sync Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_SYNC_RCLONE_OPTS="--fast-list --ignore-errors -v"

# Load backends
if [ -n "$BACKUP_SYNC_BACKENDS" ]; then
	BACKUP_SYNC_BACKENDS="${BACKUP_SYNC_BACKENDS//,/ }"
	for BACKUP_SYNC_BACKEND in $BACKUP_SYNC_BACKENDS; do
		BACKUP_SYNC_BACKEND_SH="${BACKUP_DIR}/backup-backend-${BACKUP_SYNC_BACKEND}.sh"
		if [ ! -e "$BACKUP_SYNC_BACKEND_SH" ]; then
			echo "Backup backend '$BACKUP_SYNC_BACKEND' does not exist (BACKUP_SYNC_BACKENDS environment variable)"
			exit 1
		else
			source "$BACKUP_SYNC_BACKEND_SH"
			if ! backup_check; then
				exit 1
			fi
		fi
	done
fi

# Sync backups
if [ -n "$BACKUP_SYNC_ARGS" ]; then
	# Environment arguments
	while read SRC_PATH TGT_PATH EXT_OPTS; do
		if [ -n "$SRC_PATH" -a -n "$TGT_PATH" ]; then
			echo "Syncing $SRC_PATH => $TGT_PATH ..."
			rclone sync $BACKUP_SYNC_RCLONE_OPTS $EXT_OPTS "$SRC_PATH" "$TGT_PATH"
		fi
	done <<< "$BACKUP_SYNC_ARGS"
else
	# Command-line arguments
	SRC_PATH="$1"
	TGT_PATH="$2"
	EXT_OPTS="${@:3}"
	if [ -z "$SRC_PATH" -o -z "$TGT_PATH" ]; then
		echo "Usage: $0 <source path> <target path> [rclone options]"
		echo "Alternatively, argument lines can be defined in a BACKUP_SYNC_ARGS environment variable."
		exit 1
	fi
	echo "Syncing $SRC_PATH => $TGT_PATH ..."
	rclone sync $BACKUP_SYNC_RCLONE_OPTS $EXT_OPTS "$SRC_PATH" "$TGT_PATH"
fi
