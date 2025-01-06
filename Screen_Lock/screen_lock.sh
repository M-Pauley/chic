#!/bin/bash
# /usr/local/bin/screen_lock.sh
#
# This script locks and unlocks a user account at specified times.

LOCK=$1  # lock or unlock action
USER=$2  # username
LOCKFILE="/var/log/screenlock.log"

log_message() {
    # Log function with timestamp
    echo "$(date) - $1" >> "$LOCKFILE"
}

# Check if the log file exists, if not create it
if [ ! -f "$LOCKFILE" ]; then
    sudo touch "$LOCKFILE"
    sudo chown root:root "$LOCKFILE"
    sudo chmod 644 "$LOCKFILE"
    log_message "Log file created at $LOCKFILE"
fi

# Ensure a user is specified
if [ -z "$USER" ]; then
    log_message "Error: No username provided."
    echo "Usage: $0 {lock|unlock} <username>"
    exit 1
fi

# Ensure lock/unlock action is specified
if [ "$LOCK" != "lock" ] && [ "$LOCK" != "unlock" ]; then
    log_message "Error: Invalid action specified. Must be 'lock' or 'unlock'."
    echo "Usage: $0 {lock|unlock} <username>"
    exit 1
fi

if [ "$LOCK" == "lock" ]; then
    # Lock the screen (if user has an active session)
    SESSIONID=$(loginctl | grep "$USER" | awk '{print $1}')
    if [ -n "$SESSIONID" ]; then
        log_message "Locking session for user: $USER (Session ID: $SESSIONID)"
        sudo loginctl lock-session "$SESSIONID"
    else
        log_message "Error: No active session found for user: $USER"
        echo "No active session found for user: $USER"
    fi

    # Lock the user account (prevent login)
    if sudo passwd -l "$USER"; then
        log_message "User account for $USER is locked."
    else
        log_message "Error: Failed to lock user account for $USER."
        echo "Failed to lock user account for $USER."
        exit 1
    fi

elif [ "$LOCK" == "unlock" ]; then
    # Unlock the user account (allow login)
    if sudo passwd -u "$USER"; then
        log_message "User account for $USER is unlocked."
    else
        log_message "Error: Failed to unlock user account for $USER."
        echo "Failed to unlock user account for $USER."
        exit 1
    fi

    # Don't unlock the session if the user is logged in (they should stay logged out)
    SESSIONID=$(loginctl | grep "$USER" | awk '{print $1}')
    if [ -n "$SESSIONID" ]; then
        log_message "User $USER is still logged in. Keeping the session locked."
    else
        log_message "No active session found for user: $USER"
    fi

else
    log_message "Error: Invalid action specified."
    echo "Usage: $0 {lock|unlock} <username>"
    exit 1
fi