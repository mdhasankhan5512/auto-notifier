#!/bin/sh

# ====== Configuration ======
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
TEMP_FILE="/tmp/temp_report.txt"
SENSORS_OUTPUT=$(sensors)

# ====== Format Message ======
echo "🌡️ *Router Temperature Report*" > "$TEMP_FILE"
echo '```' >> "$TEMP_FILE"
echo "$SENSORS_OUTPUT" >> "$TEMP_FILE"
echo '```' >> "$TEMP_FILE"

# ====== Send to Telegram ======
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d parse_mode="Markdown" \
  --data-urlencode text@"$TEMP_FILE"

# Clean up
rm -f "$TEMP_FILE"
