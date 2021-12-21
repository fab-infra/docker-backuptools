#!/bin/bash
#
# MySQL Backup Script
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
MAX_BACKUPS=${MAX_BACKUPS:-30}
BACKUP_DIR="${BACKUP_DIR:-/home/backups}"
BACKUP_BACKEND="${BACKUP_BACKEND:-fs}"
BACKUP_BACKEND_SH="${BACKUP_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
BACKUP_SUBDIR="${BACKUP_SUBDIR:-mysql}"
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-dumpuser}"
MYSQL_DB_EXCLUDE="${MYSQL_DB_EXCLUDE:-test information_schema performance_schema}"

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

# Loop over databases
DB_LIST=`mysqlshow -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD | tail -n+4 | head -n-1 | cut -d' ' -f2`
for DB in $DB_LIST; do
	ISEXCLUDED=0
	for EXCL in $MYSQL_DB_EXCLUDE; do
		if [ "$DB" = "$EXCL" ]; then
			ISEXCLUDED=1
		fi
	done
	if [ $ISEXCLUDED -eq 1 ]; then
		continue
	fi
	
	# Create archive name
	DATESTRING=`date +"%Y%m%dT%H%M%S"`
	ARCHIVE_DIR="$BACKUP_SUBDIR/$DB"
	ARCHIVE_NAME="$DB-$DATESTRING.xz"
	
	# Create backup archive
	echo "Creating MySQL backup archive '$ARCHIVE_NAME' for database '$DB'..."
	if mysqldump -c --opt -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD "$DB" | xz > "$TMP_DIR/$ARCHIVE_NAME"; then
		if backup_save "$ARCHIVE_DIR" "$TMP_DIR/$ARCHIVE_NAME"; then
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			backup_prune "$ARCHIVE_DIR" "^$DB" "$MAX_BACKUPS"
		else
			echo "ERROR: failed to save MySQL backup archive '$ARCHIVE_NAME' for database '$DB' (exit code: $?)"
			rm -f "$TMP_DIR/$ARCHIVE_NAME"
			FAILURE=1
		fi
	else
		echo "ERROR: failed to create MySQL backup archive '$TMP_DIR/$ARCHIVE_NAME' for database '$DB' (exit code: $?)"
		rm -f "$TMP_DIR/$ARCHIVE_NAME"
		FAILURE=1
	fi
done

# Cleanup
if [ -e "$TMP_DIR" ]; then
	rm -Rf "$TMP_DIR"
fi

exit $FAILURE
