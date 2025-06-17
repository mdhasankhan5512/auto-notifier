#!/bin/sh

MAC_LIST="/root/mac.txt"
BLACKLIST="/root/blacklisted.txt"
LEASE_FILE="/tmp/dhcp.leases"
TOKEN="YOUR TELEGRAM BOT TOKEN"
CHAT_ID="YOUR TELEGRAM CHAT ID"

touch "$MAC_LIST" "$BLACKLIST"

while read -r _ MAC IP NAME _; do
  [ -z "$NAME" ] && NAME="*"

  # Skip if already approved or blacklisted
  grep -iq "^$MAC" "$MAC_LIST" && continue
  grep -iq "^$MAC" "$BLACKLIST" && continue

  # Construct the message inside the loop so variables have values
  MESSAGE="🆕 New Device Detected
MAC: $MAC
IP: $IP
Name: $NAME

Reply with /allow-$MAC-$IP-$NAME or /deny-$MAC-$IP-$NAME"

  # Send Telegram alert for new device
  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE" \
    -d parse_mode="Markdown"
done < "$LEASE_FILE"
