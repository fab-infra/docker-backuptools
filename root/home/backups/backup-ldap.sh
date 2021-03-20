#!/bin/bash
#
# LDAP Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
MAX_BACKUPS=${MAX_BACKUPS:-30}
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_BACKEND="${BACKUP_BACKEND:-swift}"
BACKUP_BACKEND_SH="${BACKUP_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-ldap}"
BACKUP_BASENAME="${BACKUP_BASENAME:-ldap}"

# Check environment
if [ ! -e "$BACKUP_BACKEND_SH" ]; then
	echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKEND environment variable)"
	exit 1
else
	. "$BACKUP_BACKEND_SH"
	backup_check || exit 1
fi

TMP_DIR=`mktemp -d`
FAILURE=0

# Create archive name
DATESTRING=`date +"%Y%m%dT%H%M%S"`
ARCHIVE_NAME="$BACKUP_BASENAME-$DATESTRING.xz"

# Create backup archive
if slapcat -f /etc/openldap/slapd.conf -n 1 | xz > "$TMP_DIR/$ARCHIVE_NAME" ; then
	if backup_save "$BACKUP_SUBDIR" "$TMP_DIR/$ARCHIVE_NAME"; then
		rm -f "$TMP_DIR/$ARCHIVE_NAME"
		backup_prune "$BACKUP_SUBDIR" "^$BACKUP_BASENAME" "$MAX_BACKUPS"
	else
		echo "ERROR: failed to save backup archive '$ARCHIVE_NAME' for LDAP directory (exit code: $?)"
		rm -f "$TMP_DIR/$ARCHIVE_NAME"
		FAILURE=1
	fi
else
	echo "ERROR: failed to create backup archive '$TMP_DIR/$ARCHIVE_NAME' for LDAP directory (exit code: $?)"
	rm -f "$TMP_DIR/$ARCHIVE_NAME"
	FAILURE=1
fi

# Cleanup
if [ -e "$TMP_DIR" ]; then
	rm -Rf "$TMP_DIR"
fi

exit $FAILURE
