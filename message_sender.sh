#!/bin/sh

TOKEN="YOUR BOT TOKEN"
MAC_LIST="/root/mac.txt"
BLACKLIST="/root/blacklisted.txt"
OFFSET_FILE="/root/telegram_offset.txt"
OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)

UPDATES=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=$OFFSET")

echo "$UPDATES" | jsonfilter -e '@.result[*]' | while read -r update; do
  MSG=$(echo "$update" | jsonfilter -e '@.message.text')
  CHAT_ID=$(echo "$update" | jsonfilter -e '@.message.chat.id')
  MSG_ID=$(echo "$update" | jsonfilter -e '@.update_id')

  echo "$MSG_ID" > "$OFFSET_FILE"

  case "$MSG" in
    /allow-*)
      # Extract fields from /allow-MAC-IP-NAME
      IFS='-' read -r _ RMAC RIP RNAME <<< "$MSG"

      # Add to MAC list if not already present
      grep -iq "^$RMAC" "$MAC_LIST" || echo "$RMAC $RIP $RNAME" >> "$MAC_LIST"

      # Apply firewall rule
      uci add firewall rule
      uci set firewall.@rule[-1].src='lan'
      uci set firewall.@rule[-1].dest='wan'
      uci set firewall.@rule[-1].name="$RNAME"
      uci add_list firewall.@rule[-1].src_mac="$RMAC"
      uci set firewall.@rule[-1].target='ACCEPT'
      uci commit firewall
      /etc/init.d/firewall restart

      # Send reply
      curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="✅ $RMAC ($RNAME) at $RIP is now allowed internet access."
      ;;

    /deny-*)
      IFS='-' read -r _ RMAC RIP RNAME <<< "$MSG"
      grep -iq "^$RMAC" "$BLACKLIST" || echo "$RMAC $RIP $RNAME" >> "$BLACKLIST"
      sed -i "/\b$RMAC\b/d" /tmp/dhcp.leases

      curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="⛔ $RMAC ($RNAME) has been denied internet access."
      ;;

    /R-blacklist-*)
      IFS='-' read -r _ RMAC <<< "$MSG"
      sed -i "/$RMAC/d" "$BLACKLIST"
      grep -iq "^$RMAC" "$MAC_LIST" || echo "$RMAC unknown unknown" >> "$MAC_LIST"

      uci add firewall rule
      uci set firewall.@rule[-1].src='lan'
      uci set firewall.@rule[-1].dest='wan'
      uci set firewall.@rule[-1].name="Recovered $RMAC"
      uci add_list firewall.@rule[-1].src_mac="$RMAC"
      uci set firewall.@rule[-1].target='ACCEPT'
      uci commit firewall
      /etc/init.d/firewall restart

      curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="♻️ $RMAC recovered and added to whitelist."
      ;;
  esac
done
