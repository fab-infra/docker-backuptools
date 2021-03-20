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
	elif [ -z "$BACKUP_FTP_PWD" ]; then
		echo "Backup FTP password must be specified (BACKUP_FTP_PWD environment variable)"
		return 1
	fi
	return 0
}

# List backup files
function backup_list
{
	local SUBDIR="$1"
	curl -l -u "$BACKUP_FTP_USER:$BACKUP_FTP_PWD" "ftp://$BACKUP_FTP_HOST/$SUBDIR/"
}

# Save a backup
function backup_save
{
	local SUBDIR="$1"
	local FILE="$2"
	curl -T "$FILE" --ftp-create-dirs -u "$BACKUP_FTP_USER:$BACKUP_FTP_PWD" "ftp://$BACKUP_FTP_HOST/$SUBDIR/"
}

# Delete a backup
function backup_delete
{
	local SUBDIR="$1"
	local FILE_NAME="$2"
	curl -Q "-DELE $FILE_NAME" -u "$BACKUP_FTP_USER:$BACKUP_FTP_PWD" "ftp://$BACKUP_FTP_HOST/$SUBDIR/"
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
	local SRC_DIR="$1"
	local EXT_OPTS="${@:3}"
	echo "WARNING: FTP backup_sync is not implemented"
}
