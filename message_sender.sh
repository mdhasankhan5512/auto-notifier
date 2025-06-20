#!/bin/sh

TOKEN="Your Bot Token"
MAC_LIST="/root/mac.txt"
BLACKLIST="/root/blacklisted.txt"
PROCESSED_DIR="/tmp/telegram_processed"

mkdir -p "$PROCESSED_DIR"

# Get the latest 100 updates
UPDATES=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?limit=100")

# Process special list commands only once per message
echo "$UPDATES" | jq -c '.result[]' | tac | while read -r LINE; do
  MSG=$(echo "$LINE" | jq -r '.message.text')
  CHAT_ID=$(echo "$LINE" | jq -r '.message.chat.id')
  MSG_ID=$(echo "$LINE" | jq -r '.message.message_id')
  HASH_FILE="$PROCESSED_DIR/msg_${MSG_ID}"

  [ -f "$HASH_FILE" ] && continue
  touch "$HASH_FILE"

  case "$MSG" in
    "/Allow-list")
      CONTENT=$(cat "$MAC_LIST" 2>/dev/null || echo "No MACs in allow list.")
      curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="📗 *Allowed Devices:\`\`\` $CONTENT\`\`\`" \
        -d parse_mode="Markdown"
      ;;

    "/Black-list")
      CONTENT=$(cat "$BLACKLIST" 2>/dev/null || echo "No MACs in blacklist.")
      curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="📕 *Blacklisted Devices:\`\`\` $CONTENT\`\`\`" \
        -d parse_mode="Markdown"
      ;;
  esac
done

# Process allow/deny/RBlacklist commands (MAC-specific)
echo "$UPDATES" | jq -r '.result[].message.text' | grep -E '^/(allow|deny|RBlacklist)-' | tail -n 100 | tac | while read -r CMD; do
  ACTION=$(echo "$CMD" | cut -d'-' -f1 | sed 's|/||')
  MAC=$(echo "$CMD" | cut -d'-' -f2)

  [ -f /tmp/processed_$MAC ] && continue
  touch /tmp/processed_$MAC

  IP=$(echo "$CMD" | cut -d'-' -f3)
  NAME=$(echo "$CMD" | cut -d'-' -f4-)

  case "$ACTION" in
    allow)
      grep -iq "^$MAC" "$MAC_LIST" || {
        echo "$MAC $IP $NAME" >> "$MAC_LIST"

        if ! uci show firewall | grep -iq "$MAC"; then
          uci add firewall rule
          uci set firewall.@rule[-1].src='lan'
          uci set firewall.@rule[-1].dest='wan'
          uci set firewall.@rule[-1].name="$(echo "$NAME" | sed 's/"/\\"/g')"
          uci add_list firewall.@rule[-1].src_mac="$MAC"
          uci set firewall.@rule[-1].target='ACCEPT'
          uci commit firewall
          /etc/init.d/firewall restart
        fi

        CHAT_ID=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -d text="✅ $MAC ($NAME) at $IP is now allowed internet access." \
          -d chat_id="$CHAT_ID"
      }
      ;;

    deny)
      BLACKLISTED=0
      RULE_REMOVED=0

      if ! grep -iq "^$MAC" "$BLACKLIST"; then
        echo "$MAC $IP $NAME" >> "$BLACKLIST"
        sed -i "/\b$MAC\b/d" /tmp/dhcp.leases
        BLACKLISTED=1
      fi
      if  grep -iq "^$MAC" "$MAC_LIST"; then
        sed -i "/\b$MAC\b/d" /root/mac.txt
      fi
      for SECTION in $(uci show firewall | grep ".src_mac='${MAC}'" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci delete firewall."$SECTION"
        RULE_REMOVED=1
      done

      if [ "$RULE_REMOVED" -eq 1 ]; then
        uci commit firewall
        /etc/init.d/firewall restart
      fi

      if [ "$BLACKLISTED" -eq 1 ] || [ "$RULE_REMOVED" -eq 1 ]; then
        CHAT_ID=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -d text="⛔ $MAC ($NAME) at $IP has been *denied* internet access.
$( [ "$BLACKLISTED" -eq 1 ] && echo '📛 Added to blacklist.' )
$( [ "$RULE_REMOVED" -eq 1 ] && echo '🧱 Firewall rule removed.' )" \
          -d parse_mode="Markdown" \
          -d chat_id="$CHAT_ID"
      fi
      ;;

    RBlacklist)
      sed -i "/$MAC/d" "$BLACKLIST"

      if ! grep -iq "^$MAC" "$MAC_LIST"; then
        echo "$MAC $IP $NAME" >> "$MAC_LIST"

        if ! uci show firewall | grep -iq "$MAC"; then
          uci add firewall rule
          uci set firewall.@rule[-1].src='lan'
          uci set firewall.@rule[-1].dest='wan'
          uci set firewall.@rule[-1].name="Recovered $NAME"
          uci add_list firewall.@rule[-1].src_mac="$MAC"
          uci set firewall.@rule[-1].target='ACCEPT'
          uci commit firewall
          /etc/init.d/firewall restart
          CHAT_ID=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
          curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
            -d text="♻️ $MAC ($NAME) at $IP recovered and added to whitelist." \
            -d chat_id="$CHAT_ID"
        fi
      fi
      ;;
  esac
done

# Clean up MAC-specific flags
rm -f /tmp/processed_*
