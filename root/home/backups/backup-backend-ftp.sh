#!/bin/bash
#
# FTP backup backend
# By Fabien CRESPEL <fabien@crespel.net>
#

# Check backend
function backup_check
{
	if [ -z "$BACKUP_FTP_HOST" ]; then
		echo "Backup FTP host must be specified (BACKUP_FTP_HOST environment variable)"
		return 1
	elif [ -z "$BACKUP_FTP_USER" ]; then
		echo "Backup FTP user must be specified (BACKUP_FTP_USER environment variable)"
		return 1
	elif [ -z "$BACKUP_FTP_PASSWORD" ]; then
		echo "Backup FTP password must be specified (BACKUP_FTP_PASSWORD environment variable)"
		return 1
	fi
	return 0
}

# List backup files
function backup_list
{
	local SUBDIR="$1"
	curl -sSf -l -u "$BACKUP_FTP_USER:$BACKUP_FTP_PASSWORD" "ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/"
}

# Save a backup
function backup_save
{
	local SUBDIR="$1"
	local FILE="$2"
	local FILE_NAME=`basename "$FILE"`
	echo "Saving 'ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/$FILE_NAME'..."
	curl -sSf -T "$FILE" --ftp-create-dirs -u "$BACKUP_FTP_USER:$BACKUP_FTP_PASSWORD" "ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/"
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	echo "Deleting 'ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/$FILE_NAME'..."
	curl -sSf -Q "-DELE $FILE_NAME" -u "$BACKUP_FTP_USER:$BACKUP_FTP_PASSWORD" "ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/"
}

# Prune outdated backups
function backup_prune
{
	local SUBDIR="$1"
	local FILE_NAME_REGEX="$2"
	local MAX_BACKUPS="$3"
	local NUMBER=1
	echo "Pruning backups in 'ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/'... (max: $MAX_BACKUPS)"
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
	echo "Syncing '$SRC_DIR' to 'ftp://$BACKUP_FTP_HOST/$BACKUP_FTP_DIR/$SUBDIR/'..."
	echo "WARNING: FTP backup_sync is not implemented"
}
