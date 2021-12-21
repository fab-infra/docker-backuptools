#!/bin/bash
#
# Configuration Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
MAX_BACKUPS=${MAX_BACKUPS:-30}
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_BACKEND="${BACKUP_BACKEND:-fs}"
BACKUP_BACKEND_SH="${BACKUP_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-config}"
BACKUP_BASENAME="${BACKUP_BASENAME:-config}"
CONFIG_LIST="${CONFIG_LIST:-$BACKUP_DIR/backup-config-list}"
CONFIG_ROOTFS="${CONFIG_ROOTFS:-}"

# Check environment
if [ ! -e "$BACKUP_BACKEND_SH" ]; then
	echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKEND environment variable)"
	exit 1
else
	. "$BACKUP_BACKEND_SH"
	backup_check || exit 1
fi

WORK_DIR=`mktemp -d`
TMP_DIR=`mktemp -d`
FAILURE=0

if [ -e "$CONFIG_LIST" ]; then
	# Copy files and directories from backup list into a temp directory
	echo "Copying config files..."
	while read ENTRY; do
		if [[ -n "$ENTRY" && "${ENTRY:0:1}" != "#" && "${ENTRY:0:2}" != "//" ]]; then
			NBFILES=`ls -1 ${CONFIG_ROOTFS}${ENTRY} 2>/dev/null | wc -l`
			if [ "$NBFILES" != "0" ]; then
				echo "$ENTRY ($NBFILES file(s))"
				cp -a --parents ${CONFIG_ROOTFS}${ENTRY} "$WORK_DIR"
			fi
		fi
	done < "$CONFIG_LIST"

	# Create archive name
	DATESTRING=`date +"%Y%m%dT%H%M%S"`
	ARCHIVE_NAME="$BACKUP_BASENAME-$DATESTRING.tar.xz"

	# Create backup archive
	echo "Creating config backup archive '$ARCHIVE_NAME'..."
	if tar -cJ -f "$TMP_DIR/$ARCHIVE_NAME" -C "$WORK_DIR" .; then
		rm -rf "$WORK_DIR"
		if backup_save "$BACKUP_SUBDIR" "$TMP_DIR/$ARCHIVE_NAME"; then
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			backup_prune "$BACKUP_SUBDIR" "^$BACKUP_BASENAME" "$MAX_BACKUPS"
		else
			echo "ERROR: failed to save config backup archive '$ARCHIVE_NAME' (exit code: $?)"
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			FAILURE=1
		fi
	else
		echo "ERROR: failed to create config backup archive '$TMP_DIR/$ARCHIVE_NAME' (exit code: $?)"
		echo "Temporary files are still in '$WORK_DIR', please check and remove them manually."
		FAILURE=1
	fi
else
	echo "ERROR: config backup list file '$CONFIG_LIST' does not exist."
	FAILURE=1
fi

# Cleanup
if [ -e "$TMP_DIR" ]; then
	rm -Rf "$TMP_DIR"
fi

exit $FAILURE
