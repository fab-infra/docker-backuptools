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
	local FILE_NAME=`basename "$FILE"`
	mkdir -p "$BACKUP_DIR/$SUBDIR" && touch "$BACKUP_DIR/$SUBDIR/$FILE_NAME" && cp "$FILE" "$BACKUP_DIR/$SUBDIR/$FILE_NAME"
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	rm -f "$BACKUP_DIR/$SUBDIR/$FILE_NAME"
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
