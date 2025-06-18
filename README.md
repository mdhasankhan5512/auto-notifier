# 🔔 Auto Notifier for OpenWrt

This project automates MAC-based network access control on OpenWrt routers using Telegram Bot notifications. Devices can be allowed, denied, or restored via Telegram commands, with real-time firewall rule updates.

## 🚀 Features

- ✅ Allow or deny devices by MAC address via Telegram commands
- 🔄 Auto-sync firewall rules for `allow`, `deny`, and `RBlacklist`
- 📥 Automatically download and install required scripts and dependencies
- 🔄 Runs continuously in background using `cron` and `rc.local`

## ⚠️ Important Firewall Warning

To ensure the script functions correctly, you **must edit the OpenWrt firewall settings**:

1. Go to **Network → Firewall**.
2. Edit the **LAN zone**.
3. Under **Allow forward to destination zones**, **remove `wan`**.
4. Click **Save & Apply**.

📷 Example screenshots:

- Before editing:

  ![Firewall Settings - Before](firewall_before.png)

- After editing:

  ![Firewall Settings - After](firewall_after.png)

If not configured properly,  Denied devices will be blacklisted from geting internet access.

---
🛠 Requirements
OpenWrt router

Telegram bot token and chat ID

Internet connectivity

Packages: jq, coreutils-tac


## 📦 Installation

wget https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/refs/heads/main/setup_notifier.sh && chmod +x setup_notifier.sh && sh setup_notifier.sh


💬 Telegram Commands Format
Command	Description
/allow-MAC-IP-Name	Allow internet access for the device
/deny-MAC-IP-Name	Deny access and blacklist the MAC
/RBlacklist-MAC-IP-Name	Remove MAC from blacklist and reallow

🔍 Example:
/allow-11:22:33:44:55:66-192.168.1.100-JohnsPhone

📃 License
This project is licensed under a creditware license:

You are free to use, modify, and distribute this software for personal or commercial use, as long as credit is given to the original author.

Author: Md Hasan Khan
🔗 Facebook Profile


