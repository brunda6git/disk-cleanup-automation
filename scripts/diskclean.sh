#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -e

# ===== CONFIG =====
MONITOR_DIR="/"
THRESHOLD=80
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGFILE="$BASE_DIR/logs/disk_cleanup.log"

# Change this email to recieve alerts
EMAIL="your_email@gmail.com"

# ===== COLORS =====
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# ===== GET DISK USAGE =====
get_usage() {
    df "$MONITOR_DIR" | awk 'NR==2 {print $5}' | sed 's/%//'
}

# ===== LOG FUNCTION =====
log(){
    TYPE=$1
    BEFORE=$2
    AFTER=$3
    echo "$(date '+%Y-%m-%d') | $(date '+%H:%M:%S') | $TYPE | $BEFORE | $AFTER" >> "$LOGFILE"
}

echo -e "${GREEN}====== DISK MONITOR STARTED ======${RESET}"

# ===== CURRENT USAGE =====
USAGE=$(df "$MONITOR_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
echo -e "${YELLOW}Current Disk Usage:${RESET} $USAGE%"

SUBJECT="DISK ALERT: $USAGE% Usage on Kali Monitor"

BEFORE=$(get_usage)

# ===== THRESHOLD CHECK =====
if [ "$USAGE" -ge "$THRESHOLD" ]; then

    echo -e "${RED}Disk usage exceeded threshold! Running cleanup...${RESET}"

FILES=$(find /tmp -type f -mtime +2 2>/dev/null)
    if [ -z "$FILES" ]; then
        echo "No files found for cleanup."
    else
        COUNT=$(echo "$FILES" | wc -l)

        echo "Files to delete:"
        echo "$FILES"

        find /tmp -type f -mtime +2 -exec rm -f {} \; 2>/dev/null
    fi

    COUNT=${COUNT:-0}

    AFTER=$(get_usage)

    echo ""
    echo "====== CLEANUP REPORT ======"
    echo "Before cleanup : $BEFORE"
    echo "After cleanup  : $AFTER"
    echo "Files removed  : $COUNT"

    # LOG CLEANUP
    log "CLEANUP" "$BEFORE" "$AFTER"

# ===== EMAIL ALERT =====
EMAIL_BODY="
======================================
DISK SPACE ALERT
======================================

Server        : Kali Disk Monitor
Disk Usage    : $USAGE%
Threshold     : $THRESHOLD%

----- CLEANUP REPORT -----

Before Cleanup : $USAGE%
After Cleanup  : $AFTER
Files Removed  : $COUNT

Directory Cleaned : /tmp

Time : $(date)

======================================
Disk Monitoring System
======================================
"

    echo "$EMAIL_BODY" | mail -s "$SUBJECT" "$EMAIL"

    # LOG EMAIL
    log "EMAIL" "$BEFORE" "$AFTER"

else

    echo -e "${GREEN}Disk usage normal.${RESET}"

    AFTER=$(get_usage)

    # LOG NORMAL
    log "NORMAL" "$BEFORE" "$AFTER"

fi

echo -e "${GREEN}====== DISK MONITOR FINISHED ======${RESET}"



