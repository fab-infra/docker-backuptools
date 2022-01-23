#!/bin/bash
#
# Files Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
SCRIPT_DIR=`dirname "$0"`
BACKUP_BACKEND="${BACKUP_BACKEND:-fs}"
BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-files}"
SRC_DIR="$1"
EXT_OPTS="${@:2}"

# Check environment
if [ ! -e "$BACKUP_BACKEND_SH" ]; then
	echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKEND environment variable)"
	exit 1
else
	. "$BACKUP_BACKEND_SH"
	backup_check || exit 1
fi

# Check argument
if [ -z "$SRC_DIR" ]; then
	echo "Usage: $0 <source directory>"
	exit 1
fi

FAILURE=0

if [ -e "$SRC_DIR" ]; then
	if ! backup_sync "$BACKUP_SUBDIR" "$SRC_DIR" $EXT_OPTS; then
		echo "ERROR: failed to backup files from '$SRC_DIR' (exit code: $?)"
		FAILURE=1
	fi
else
	echo "ERROR: source directory '$SRC_DIR' does not exist."
	FAILURE=1
fi

exit $FAILURE
