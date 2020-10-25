#!/bin/bash
#
# Configuration Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
MAX_BACKUPS=12
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_BACKEND="${BACKUP_BACKEND:-$BACKUP_DIR/backup-backend-swift.sh}"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-config}"
BACKUP_BASENAME="${BACKUP_BASENAME:-config}"
CONFIG_LIST="${CONFIG_LIST:-$BACKUP_DIR/backup-config-list}"

# Check environment
if [ ! -e "$BACKUP_BACKEND" ]; then
	echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKEND environment variable)"
	exit 1
else
	. "$BACKUP_BACKEND"
	backup_check || exit 1
fi

WORK_DIR=`mktemp -d`
TMP_DIR=`mktemp -d`
OUTPUT_FILE=`mktemp`
FAILURE=0

if [ -e "$CONFIG_LIST" ]; then
	# Copy files and directories from backup list into a temp directory
	echo "Archiving..." >> $OUTPUT_FILE
	while read ENTRY ; do
		if [[ -n "$ENTRY" && "${ENTRY:0:1}" != "#" && "${ENTRY:0:2}" != "//" ]] ; then
			NBFILES=`ls -1 $ENTRY 2>/dev/null | wc -l`
			if [ "$NBFILES" != "0" ] ; then
				echo "$ENTRY ($NBFILES file(s))" >> $OUTPUT_FILE
				cp -a --parents $ENTRY "$WORK_DIR"
			fi
		fi
	done < "$CONFIG_LIST"

	# Create archive name
	DATESTRING=`date +"%Y%m%dT%H%M%S"`
	ARCHIVE_NAME="$BACKUP_BASENAME-$DATESTRING.tar.xz"

	# Create backup archive
	echo "Creating backup archive '$ARCHIVE_NAME'..." >> $OUTPUT_FILE
	if tar -cJ -f "$TMP_DIR/$ARCHIVE_NAME" -C "$WORK_DIR" . ; then
		rm -rf "$WORK_DIR"
		if backup_save "$BACKUP_SUBDIR" "$TMP_DIR/$ARCHIVE_NAME" >> $OUTPUT_FILE; then
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			backup_prune "$BACKUP_SUBDIR" "^$BACKUP_BASENAME" "$MAX_BACKUPS" >> $OUTPUT_FILE
		else
			echo "ERROR: failed to save backup archive '$ARCHIVE_NAME' (exit code: $?)" >> $OUTPUT_FILE
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			FAILURE=1
		fi
	else
		echo "ERROR: failed to create backup archive '$TMP_DIR/$ARCHIVE_NAME' (exit code: $?)" >> $OUTPUT_FILE
		echo "Temporary files are still in $WORK_DIR, please check and remove them manually." >> $OUTPUT_FILE
		FAILURE=1
	fi
else
	echo "The backup list file '$CONFIG_LIST' does not exist." >> $OUTPUT_FILE
	FAILURE=1
fi

# Cleanup
if [ -e "$TMP_DIR" ]; then
	rm -Rf "$TMP_DIR"
fi

# Show messages
if [ $FAILURE -ne 0 ]; then
	cat $OUTPUT_FILE
fi
rm -f $OUTPUT_FILE

exit $FAILURE
