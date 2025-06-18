#!/bin/sh

MAC_LIST="/root/mac.txt"
BLACKLIST="/root/blacklisted.txt"
LEASE_FILE="/tmp/dhcp.leases"
TOKEN="YOUR TELEGRAM BOT TOKEN"
CHAT_ID="YOUR TELEGRAM CHAT ID"

[ -f "$MAC_LIST" ] || touch "$MAC_LIST"
[ -f "$BLACKLIST" ] || touch "$BLACKLIST"

while read -r _ MAC IP NAME _; do
[ "$NAME" = "*" ] && NAME="Unknown Device"

  # Skip if already approved or blacklisted
  grep -iq "^$MAC" "$MAC_LIST" && continue
  grep -iq "^$MAC" "$BLACKLIST" && continue

  # Escape Markdown special characters
  ESCAPED_NAME=$(echo "$NAME" | sed -e 's/_/\\_/g' -e 's/*/\\*/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/(/\\(/g' -e 's/)/\\)/g')

  # Construct and send message
  MESSAGE="🆕 New Device Detected
MAC: $MAC
IP: $IP
Name: $ESCAPED_NAME

Reply with /allow-$MAC-$IP-$NAME or /deny-$MAC-$IP-$NAME"

  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE" \
    -d parse_mode="Markdown"
done < "$LEASE_FILE"
