#!/bin/sh
# Update and install required packages
opkg update && opkg install jq coreutils-tac
# Download scripts
wget https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/message_sender.sh -O /usr/bin/message_sender.sh
chmod +x /usr/bin/message_sender.sh
wget https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/auto_scanner.sh -O /usr/bin/auto_scanner.sh
chmod +x /usr/bin/auto_scanner.sh
wget https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/loop.sh -O /usr/bin/loop.sh
chmod +x /usr/bin/loop.sh
# Add to crontab (run every minute)
/etc/init.d/cron enable
/etc/init.d/cron start
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/auto_scanner.sh") | crontab -
# Add loop.sh to rc.local if not already added
grep -q '/usr/bin/loop.sh' /etc/rc.local || sed -i '/exit 0/i /usr/bin/loop.sh &' /etc/rc.local
# Show credit in light green (if terminal supports ANSI colors)
echo
echo -e "\033[1;92m======================== C R E D I T ========================\033[0m"
echo -e "\033[1;92m This script is created by Md Hasan Khan\033[0m"
echo -e "\033[1;92m Facebook: https://www.facebook.com/hasan2unknown \033[0m"
echo -e "\033[1;92m============================================================\033[0m"
echo
sleep 7

