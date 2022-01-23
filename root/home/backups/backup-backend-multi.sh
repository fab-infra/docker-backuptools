#!/bin/bash
#
# Multi-backends backup backend
# By Fabien CRESPEL <fabien@crespel.net>
#

# Script variables
SCRIPT_DIR=${SCRIPT_DIR:-$(dirname "$0")}

# Check backend
function backup_check
{
	if [ -z "$BACKUP_BACKENDS" ]; then
		echo "Backup backends must be specified (BACKUP_BACKENDS environment variable)"
		return 1
	fi
	BACKUP_BACKENDS="${BACKUP_BACKENDS//,/ }"
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if [ ! -e "$BACKUP_BACKEND_SH" ]; then
			echo "Backup backend '$BACKUP_BACKEND' does not exist (BACKUP_BACKENDS environment variable)"
			return 1
		elif ! ( source "$BACKUP_BACKEND_SH" && backup_check ); then
			return 1
		fi
	done
	return 0
}

# List backup files
function backup_list
{
	local RET=0
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if ! ( source "$BACKUP_BACKEND_SH" && backup_list "$@" ); then
			RET=1
			break
		fi
	done
	return $RET
}

# Save a backup
function backup_save
{
	local RET=0
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if ! ( source "$BACKUP_BACKEND_SH" && backup_save "$@" ); then
			RET=1
		fi
	done
	return $RET
}

# Delete a backup
function backup_delete
{
	local RET=0
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if ! ( source "$BACKUP_BACKEND_SH" && backup_delete "$@" ); then
			RET=1
		fi
	done
	return $RET
}

# Prune outdated backups
function backup_prune
{
	local RET=0
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if ! ( source "$BACKUP_BACKEND_SH" && backup_prune "$@" ); then
			RET=1
		fi
	done
	return $RET
}

# Sync files
function backup_sync
{
	local RET=0
	for BACKUP_BACKEND in $BACKUP_BACKENDS; do
		local BACKUP_BACKEND_SH="${SCRIPT_DIR}/backup-backend-${BACKUP_BACKEND}.sh"
		if ! ( source "$BACKUP_BACKEND_SH" && backup_sync "$@" ); then
			RET=1
		fi
	done
	return $RET
}
