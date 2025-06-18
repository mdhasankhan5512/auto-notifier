# 🔔 Auto Notifier for OpenWrt

This project automates MAC-based network access control on OpenWrt routers using Telegram Bot notifications. Devices can be allowed, denied, or restored via Telegram commands, with real-time firewall rule updates.

## 🚀 Features

- ✅ Allow or deny devices by MAC address via Telegram commands
- 🔄 Auto-sync firewall rules for `allow`, `deny`, and `RBlacklist`
- 📥 Automatically download and install required scripts and dependencies
- 🔄 Runs continuously in background using `cron` and `rc.local`

## 📂 Included Scripts

| Script              | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `setup_notifier.sh` | Installer script to set up dependencies, scripts, and ask for bot config   |
| `auto_scanner.sh`   | Scans for Telegram commands and updates firewall rules                     |
| `message_sender.sh` | Sends Telegram alerts when changes are made                                |
| `loop.sh`           | Continuously monitors and reports device states                            |
| `temp-notifier.sh`  | Experimental script (if any new feature testing)                           |

## 📦 Installation

```sh
wget https://raw.githubusercontent.com/mdhasankhan5512/auto-notifier/main/setup_notifier.sh -O - | sh


![image](https://github.com/user-attachments/assets/fb608cb6-d7d0-4000-8342-d24b944be625)


![image](https://github.com/user-attachments/assets/0fe43423-8e84-4375-9211-7b02be422d1d)
