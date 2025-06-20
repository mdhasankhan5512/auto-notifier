#!/bin/sh

# Update and install required packages
opkg update && opkg install jq coreutils-tac curl

# Download scripts
wget -q https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/message_sender.sh -O /usr/bin/message_sender.sh
chmod +x /usr/bin/message_sender.sh

wget -q https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/auto_scanner.sh -O /usr/bin/auto_scanner.sh
chmod +x /usr/bin/auto_scanner.sh

wget -q https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/loop.sh -O /usr/bin/loop.sh
chmod +x /usr/bin/loop.sh

# Ask user for Telegram setup
read -p "Do you want to set up your Telegram Bot Token and Chat ID now? [Y/n]: " setup

# Convert to lowercase for case-insensitive comparison
setup=$(echo "$setup" | tr '[:upper:]' '[:lower:]')

if [ "$setup" = "y" ] || [ "$setup" = "yes" ] || [ -z "$setup" ]; then
  read -p "Enter your Telegram Bot Token: " token
  read -p "Enter your Telegram Chat ID: " chatid

  # Escape special characters for sed
  safe_token=$(printf '%s\n' "$token" | sed 's/[&/\]/\\&/g')
  safe_chatid=$(printf '%s\n' "$chatid" | sed 's/[&/\]/\\&/g')

  # Inject token and chat id into scripts
  sed -i "s|^TOKEN=.*|TOKEN=\"$safe_token\"|" /usr/bin/auto_scanner.sh
  sed -i "s|^CHAT_ID=.*|CHAT_ID=\"$safe_chatid\"|" /usr/bin/auto_scanner.sh
  sed -i "s|^TOKEN=.*|TOKEN=\"$safe_token\"|" /usr/bin/message_sender.sh

  echo "✅ Telegram Bot Token and Chat ID have been configured."
else
  echo "⚠️ Skipped Telegram setup. You can manually edit /usr/bin/auto_scanner.sh and /usr/bin/message_sender.sh later."
fi

# Ask for admin device name and MAC address (without colons)
read -p "Enter first admin device name: " ANAME
read -p "Enter MAC address of admin device (without colons): " AMAC_RAW

# Validate MAC length (should be 12 hex digits)
if ! echo "$AMAC_RAW" | grep -qiE '^[0-9a-f]{12}$'; then
  echo "❌ Invalid MAC address format. Must be 12 hex digits without colons."
  exit 1
fi

# Convert MAC to colon format (xx:xx:xx:xx:xx:xx)
AMAC=$(echo "$AMAC_RAW" | sed 's/../&:/g;s/:$//')

echo "Adding firewall rule for device '$ANAME' with MAC $AMAC..."

# Add firewall rule via uci
uci add firewall rule
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].dest='wan'
uci set firewall.@rule[-1].name="$ANAME"
uci add_list firewall.@rule[-1].src_mac="$AMAC"
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

echo "✅ Firewall rule added and firewall restarted."

# Add to crontab (run every minute)
/etc/init.d/cron enable
/etc/init.d/cron start
(crontab -l 2>/dev/null | grep -v auto_scanner.sh; echo "* * * * * /usr/bin/auto_scanner.sh") | crontab -
# Clean up old processed message logs every 2 days
echo "0 0 */2 * * rm -f /tmp/telegram_processed/msg_*" | crontab -

# Add loop.sh to rc.local if not already added
grep -q '/usr/bin/loop.sh' /etc/rc.local || sed -i '/exit 0/i /usr/bin/loop.sh &' /etc/rc.local

# Show credit in light green
echo
echo -e "\033[1;92m======================== C R E D I T ========================\033[0m"
echo -e "\033[1;92m This script is created by Md Hasan Khan\033[0m"
echo -e "\033[1;92m Facebook: https://www.facebook.com/hasan2unknown \033[0m"
echo -e "\033[1;92m============================================================\033[0m"
echo
sleep 7

# Apply default firewall zone forward policy
uci set firewall.@zone[0].forward='REJECT'
uci commit firewall
/etc/init.d/firewall restart
