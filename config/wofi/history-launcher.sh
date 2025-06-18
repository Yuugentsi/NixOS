#!/bin/bash

HISTORY="$HOME/.config/wofi/history.txt"
TMP_APPS=$(mktemp)

app_list=$(wofi --show drun --print-entry | cut -d' ' -f1 | sort -u)

touch "$HISTORY"
for app in $app_list; do
    grep -qxF "$app" "$HISTORY" || echo "$app" >> "$HISTORY"
done

ordered_list=$(awk 'NF' "$HISTORY" | grep -Fx -f <(echo "$app_list") 2>/dev/null)

choice=$(echo "$ordered_list" | wofi --dmenu --prompt "Favoritos 🔝")

if [ -n "$choice" ]; then
    grep -vFx "$choice" "$HISTORY" > "$TMP_APPS"
    echo "$choice" | cat - "$TMP_APPS" > "$HISTORY"
    rm "$TMP_APPS"

    gtk-launch "$choice"
fi
