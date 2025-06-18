#!/run/current-system/sw/bin/bash

WAL_COLORS_FILE="$HOME/.cache/wal/colors.json"

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [ -n "$artist" ] && [ -n "$title" ]; then
    if [ -n "$art_url" ] && command -v wal >/dev/null && command -v jq >/dev/null; then
        wal -s -n -i "$art_url" >/dev/null 2>&1
        ACCENT_COLOR=$(jq -r '.colors.color1' "$WAL_COLORS_FILE" 2>/dev/null)
        
        if [ -z "$ACCENT_COLOR" ]; then
            ACCENT_COLOR="#1DB954"
        fi
    else
        ACCENT_COLOR="#1DB954"
    fi

    position=$(playerctl position 2>/dev/null | cut -d'.' -f1)
    duration_us=$(playerctl metadata mpris:length 2>/dev/null)
    duration_sec=$((duration_us / 1000000))

    if (( duration_sec > 0 )); then
        progress_percent=$(( (position * 100) / duration_sec ))
    else
        progress_percent=0
    fi

    bar_length=8 
    indicator_position=$(( (progress_percent * bar_length) / 100 ))

    progress_bar=""
    for (( i=0; i<bar_length; i++ )); do
        if (( i < indicator_position )); then
            progress_bar+="<span foreground='$ACCENT_COLOR'>━</span>"
        elif (( i == indicator_position )); then
            progress_bar+="<span foreground='#FFFFFF'>●</span>"
        else
            progress_bar+="<span foreground='#505050'>─</span>"
        fi
    done

    current_minutes=$((position / 60))
    current_seconds=$((position % 60))
    total_minutes=$((duration_sec / 60))
    total_seconds=$((duration_sec % 60))

    MAX_ARTIST_LEN=100
    MAX_TITLE_LEN=100 

    display_artist="$artist"
    display_title="$title"

    if [[ ${#display_artist} -gt $MAX_ARTIST_LEN ]]; then
        display_artist="${display_artist:0:$MAX_ARTIST_LEN}…"
    fi
    if [[ ${#display_title} -gt $MAX_TITLE_LEN ]]; then
        display_title="${display_title:0:$MAX_TITLE_LEN}…"
    fi

    printf "<span font_size='small'><span foreground='#F8F8F2'>%s</span> - <span foreground='$ACCENT_COLOR'>%s</span> %s [<span foreground='#F8F8F2'>%d:%02d</span>/<span foreground='#8BE9FD'>%d:%02d</span>]</span>\n" \
        "$display_artist" "$display_title" "$progress_bar" \
        "$current_minutes" "$current_seconds" \
        "$total_minutes" "$total_seconds"
else
    printf "\n"
fi