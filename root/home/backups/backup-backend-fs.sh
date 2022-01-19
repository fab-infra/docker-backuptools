#!/bin/bash
#
# Filesystem backup backend
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"

# Check backend
function backup_check
{
	if [ ! -d "$BACKUP_DIR" ]; then
		echo "Backup directory '$BACKUP_DIR' is not a valid directory (BACKUP_DIR environment variable)"
		return 1
	fi
	return 0
}

# List backup files
function backup_list
{
	local SUBDIR="$1"
	ls -1 "$BACKUP_DIR/$SUBDIR"
}

# Save a backup
function backup_save
{
	local SUBDIR="$1"
	local FILE="$2"
	local LINK="$3"
	local FILE_NAME=`basename "$FILE"`
	local RET=0
	echo "Saving '$BACKUP_DIR/$SUBDIR/$FILE_NAME'..."
	mkdir -p "$BACKUP_DIR/$SUBDIR" && touch "$BACKUP_DIR/$SUBDIR/$FILE_NAME" && cp "$FILE" "$BACKUP_DIR/$SUBDIR/$FILE_NAME"
	RET=$?
	if [ $RET -eq 0 -a -n "$LINK" ]; then
		echo "Creating symlink '$BACKUP_DIR/$SUBDIR/$LINK'..."
		ln -sf "$FILE_NAME" "$BACKUP_DIR/$SUBDIR/$LINK"
		RET=$?
	fi
	return $RET
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	echo "Deleting '$BACKUP_DIR/$SUBDIR/$FILE_NAME'..."
	rm -f "$BACKUP_DIR/$SUBDIR/$FILE_NAME"
}

# Prune outdated backups
function backup_prune
{
	local SUBDIR="$1"
	local FILE_NAME_REGEX="$2"
	local MAX_BACKUPS="$3"
	local NUMBER=1
	echo "Pruning backups in '$BACKUP_DIR/$SUBDIR/'... (max: $MAX_BACKUPS)"
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
	local DEF_OPTS="--archive --delete-excluded --ignore-errors -v"
	if [ -e "$SRC_DIR/backup.filter" ]; then
		DEF_OPTS="$DEF_OPTS --filter='merge $SRC_DIR/backup.filter'"
	fi
	echo "Syncing '$SRC_DIR' to '$BACKUP_DIR/$SUBDIR/'..."
	rsync $DEF_OPTS $EXT_OPTS "$SRC_DIR/" "$BACKUP_DIR/$SUBDIR/"
}
