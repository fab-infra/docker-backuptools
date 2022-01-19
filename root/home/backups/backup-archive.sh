#!/bin/bash
#
# Archive Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
MAX_BACKUPS=${MAX_BACKUPS:-3}
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_BACKEND="${BACKUP_BACKEND:-fs}"
BACKUP_BACKEND_SH="${BACKUP_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-archive}"
BACKUP_BASENAME="$1"
SOURCE_DIR="$2"
FILE_PATTERN="${3:-*}"

# Check environment
if [ ! -e "$BACKUP_BACKEND_SH" ]; then
	echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKEND environment variable)"
	exit 1
else
	. "$BACKUP_BACKEND_SH"
	backup_check || exit 1
fi

# Check arguments
if [ -z "$BACKUP_BASENAME" -o -z "$SOURCE_DIR" ]; then
	echo "Usage: $0 <archive basename> <source directory> [file pattern]"
	exit 1
elif [ ! -d "$SOURCE_DIR" ]; then
	echo "Source directory '$SOURCE_DIR' is not a valid directory"
	exit 1
fi

TMP_DIR=`mktemp -d`
FAILURE=0

# Create archive name
DATESTRING=`date +"%Y-%m-%d"`
ARCHIVE_NAME="${BACKUP_BASENAME}_${DATESTRING}.zip"

# Create backup archive
echo "Creating backup archive '$ARCHIVE_NAME'..."
if ( cd "$SOURCE_DIR" && zip -q "$TMP_DIR/$ARCHIVE_NAME" $FILE_PATTERN ); then
	if backup_save "$BACKUP_SUBDIR" "$TMP_DIR/$ARCHIVE_NAME" "$BACKUP_BASENAME.zip"; then
		rm -f "$TMP_DIR/$ARCHIVE_NAME"
		backup_prune "$BACKUP_SUBDIR" "^${BACKUP_BASENAME}_" "$MAX_BACKUPS"
	else
		echo "ERROR: failed to save backup archive '$ARCHIVE_NAME' (exit code: $?)"
		rm -f "$TMP_DIR/$ARCHIVE_NAME"
		FAILURE=1
	fi
else
	echo "ERROR: failed to create backup archive '$TMP_DIR/$ARCHIVE_NAME' (exit code: $?)"
	rm -f "$TMP_DIR/$ARCHIVE_NAME"
	FAILURE=1
fi

# Cleanup
if [ -e "$TMP_DIR" ]; then
	rm -Rf "$TMP_DIR"
fi

exit $FAILURE
