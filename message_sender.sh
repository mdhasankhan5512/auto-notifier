#!/bin/sh

TOKEN="YOUR TELEGRAM BOT TOKEN"
MAC_LIST="/root/mac.txt"
BLACKLIST="/root/blacklisted.txt"

# Get the latest 100 updates (more than 2 just to be safe)
UPDATES=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?limit=100")

# Extract and prioritize latest commands per MAC
echo "$UPDATES" | jq -r '.result[].message.text' | grep -E '^/(allow|deny|RBlacklist)-' | tail -n 100 | tac | while read -r CMD; do
  ACTION=$(echo "$CMD" | cut -d'-' -f1 | sed 's|/||')
  MAC=$(echo "$CMD" | cut -d'-' -f2)

  # Skip if already handled
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

        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -d text="✅ $MAC ($NAME) at $IP is now allowed internet access." \
          -d chat_id=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
      }
      ;;

    deny)
      BLACKLISTED=0
      RULE_REMOVED=0

      # 1) Add to blacklist if not already there
      if ! grep -iq "^$MAC" "$BLACKLIST"; then
        echo "$MAC $IP $NAME" >> "$BLACKLIST"
        sed -i "/\b$MAC\b/d" /tmp/dhcp.leases
        BLACKLISTED=1
      fi

      # 2) Remove any firewall rule for the MAC
      for SECTION in $(uci show firewall | grep ".src_mac='${MAC}'" | cut -d'.' -f2 | cut -d'=' -f1); do
        uci delete firewall."$SECTION"
        RULE_REMOVED=1
      done

      if [ "$RULE_REMOVED" -eq 1 ]; then
        uci commit firewall
        /etc/init.d/firewall restart
      fi

      # 3) Notify if either blacklisted or firewall rule removed
      if [ "$BLACKLISTED" -eq 1 ] || [ "$RULE_REMOVED" -eq 1 ]; then
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -d text="⛔ $MAC ($NAME) at $IP has been *denied* internet access.
$( [ "$BLACKLISTED" -eq 1 ] && echo '📛 Added to blacklist.' )
$( [ "$RULE_REMOVED" -eq 1 ] && echo '🧱 Firewall rule removed.' )" \
          -d parse_mode="Markdown" \
          -d chat_id=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
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
          curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
         -d text="♻️ $MAC ($NAME) at $IP recovered and added to whitelist." \
         -d chat_id=$(echo "$UPDATES" | jq '.result[-1].message.chat.id')
        fi
      fi

  esac
done

# Clean up flags
rm -f /tmp/processed_*
