#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LAST_SELECTED_FILE="/tmp/last_wofi_selection_${USER}"
readonly SEPARATOR="━━━━━━━━━━━━━━━━━━━━━"

declare -A LINKS=(
  ["⭐ Favorites"]="SUBMENU:favorite_links"
  ["📂 AI"]="SUBMENU:ai_links"
  ["📺 Media"]="SUBMENU:media_links"
  ["🌐 Social"]="SUBMENU:social_links"
  ["💻 Programs"]="SUBMENU:program_links"
  ["📂 Configs"]="SUBMENU:config_files"
  ["favorite_links:.config"]="SUBMENU:dot_config_links"
  ["favorite_links:❄️ NixOS"]="SUBMENU:nixos_links"
  ["favorite_links:💬 4chan"]="SUBMENU:fourchan_links"
  ["nixos_links:❄️ Configuration"]="sudo:nano:/etc/nixos/configuration.nix"
  ["nixos_links:📂 Modules"]="SUBMENU:nixos_modules"
  ["nixos_modules:📦 Packages"]="sudo:nano:/etc/nixos/modules/packages.nix:REBUILD_NIXOS"
  ["nixos_modules:🔤 Fonts"]="sudo:nano:/etc/nixos/modules/fonts.nix"
  ["nixos_modules:🌐 Locale"]="sudo:nano:/etc/nixos/modules/locale.nix"
  ["nixos_modules:⚡ Zram"]="sudo:nano:/etc/nixos/modules/zram.nix"
  ["fourchan_links:🎞️ Anime & Manga (/a/)"]="https://boards.4chan.org/a/"
  ["fourchan_links:💻 Technology (/g/)"]="https://boards.4chan.org/g/"
  ["fourchan_links:📰 News (/news/)"]="https://boards.4chan.org/news/"
  ["fourchan_links:🎵 Music (/mu/)"]="https://boards.4chan.org/mu/"
  ["fourchan_links:📷 Photography (/p/)"]="https://boards.4chan.org/p/"
  ["fourchan_links:🖼️ Wallpapers (/w/)"]="https://boards.4chan.org/w/"
  ["fourchan_links:📽️ WebM (/wsg/)"]="https://boards.4chan.org/wsg/"
  ["ai_links:🤖 ChatGPT"]="https://chatgpt.com/"
  ["ai_links:🪐 Gemini"]="https://gemini.google.com"
  ["ai_links:⚡ Grok"]="https://grok.com/"
  ["ai_links:💡 Claude"]="https://claude.ai"
  ["ai_links:🚀 Qwen"]="https://chat.qwen.ai"
  ["ai_links:🔍 DeepSeek"]="https://www.deepseek.com/"
  ["ai_links:🤖 Perplexity"]="https://www.perplexity.ai"
  ["media_links:🎥 YouTube"]="https://youtube.com"
  ["media_links:🎶 YouTube Music"]="https://music.youtube.com"
  ["social_links:📘 Facebook"]="https://facebook.com"
  ["social_links:🔍 Reddit"]="https://reddit.com"
  ["social_links:🐦 Twitter"]="https://twitter.com"
  ["social_links:🎵 Last.fm"]="https://www.last.fm"
  ["social_links:🎬 Letterboxd"]="https://letterboxd.com"
  ["social_links:🎮 Discord"]="https://discord.com"
  ["social_links:📷 Pinterest"]="https://pinterest.com"
  ["social_links:🌐 Tumblr"]="https://tumblr.com"
  ["social_links:💬 4chan"]="SUBMENU:fourchan_links"
  ["program_links:📨 Telegram"]="program:telegram-desktop"
  ["program_links:🦊 Firefox"]="program:firefox"
  ["dot_config_links:📟 Waybar"]="SUBMENU:waybar_config_links"
  ["dot_config_links:🌊 hyprland.conf"]="/home/ls/.config/hypr/hyprland.conf"
  ["dot_config_links:🐱 kitty.conf"]="/home/ls/.config/kitty/kitty.conf"
  ["waybar_config_links:⚙️ Config"]="/home/ls/.config/waybar/config"
  ["waybar_config_links:🎨 Style"]="/home/ls/.config/waybar/style.css"
  ["waybar_config_links:📦 Modules"]="SUBMENU:waybar_script_modules"
)

declare -a NAVIGATION_STACK=()

log_error() {
  echo "Error: $1" >&2
}

check_dependencies() {
  local deps=("wofi" "xdg-open" "mousepad" "nano" "kitty" "thunar")
  for dep in "${deps[@]}"; do
    command -v "$dep" &>/dev/null || { log_error "Dependency '$dep' not found"; exit 1; }
  done
}

get_last_selection() {
  [[ -f "$LAST_SELECTED_FILE" ]] && cat "$LAST_SELECTED_FILE" 2>/dev/null || echo ""
}

save_selection() {
  echo "$1" > "$LAST_SELECTED_FILE"
}

push_to_stack() {
  NAVIGATION_STACK+=("$1")
}

pop_from_stack() {
  if [[ ${#NAVIGATION_STACK[@]} -gt 0 ]]; then
    local last_index=$(( ${#NAVIGATION_STACK[@]} - 1 ))
    unset 'NAVIGATION_STACK[last_index]'
    NAVIGATION_STACK=("${NAVIGATION_STACK[@]}")
  fi
}

peek_stack() {
  [[ ${#NAVIGATION_STACK[@]} -gt 0 ]] && echo "${NAVIGATION_STACK[${#NAVIGATION_STACK[@]}-1]}" || echo ""
}

build_menu_options() {
  local last_choice="$1"
  local options=("⭐ Favorites" "📂 AI")
  local sorted_links=("📺 Media" "🌐 Social" "💻 Programs")

  if [[ -n "$last_choice" && "$last_choice" != "$SEPARATOR" && "$last_choice" != "⭐ Favorites" && "$last_choice" != "📂 AI" ]]; then
    for category in "${sorted_links[@]}"; do
      local submenu_key="${LINKS[$category]##*:}"
      [[ -n "${LINKS[$submenu_key:$last_choice]:-}" ]] && options+=("$category") && sorted_links=("${sorted_links[@]/$category/}")
    done
  fi

  for link in "${sorted_links[@]}"; do
    [[ -n "$link" ]] && options+=("$link")
  done

  options+=("$SEPARATOR" "📂 Configs")
  printf '%s\n' "${options[@]}"
}

build_submenu_options() {
  local submenu_key="$1"
  local options=("⬅ Back")
  local items=()

  if [[ "$submenu_key" == "favorite_links" ]]; then
    items=(".config" "❄️ NixOS" "💬 4chan")
  elif [[ "$submenu_key" == "dot_config_links" ]]; then
    items=("📟 Waybar" "🌊 hyprland.conf" "🐱 kitty.conf")
  elif [[ "$submenu_key" == "music_links" ]]; then
    :
  elif [[ "$submenu_key" == "waybar_script_modules" ]]; then
    options+=("📁 Open Scripts Folder")
    local base_path="/home/ls/.config/waybar/scripts"
    if [[ -d "$base_path" ]]; then
      while IFS= read -r -d '' file; do
        file_name=$(basename "$file")
        case "$file_name" in
          battery-level.sh) items+=("🔋 $file_name");;
          battery-state.sh) items+=("⚡ $file_name");;
          brightness-control.sh) items+=("💡 $file_name");;
          links.sh) items+=("🔗 $file_name");;
          playerctl-status.sh) items+=("🎵 $file_name");;
          volume-control.sh) items+=("🔊 $file_name");;
          wifi-menu.sh) items+=("📶 $file_name");;
          wifi-status.sh) items+=("📡 $file_name");;
          *) items+=("📄 $file_name");;
        esac
      done < <(find "$base_path" -maxdepth 1 -type f -executable -print0)
    fi
  else
    for key in "${!LINKS[@]}"; do
      [[ "$key" == $submenu_key:* ]] && items+=("${key#$submenu_key:}")
    done
  fi

  if [[ "$submenu_key" == "waybar_config_links" ]]; then
    items=("⚙️ Config" "🎨 Style" "📦 Modules")
  elif [[ "$submenu_key" != "favorite_links" && "$submenu_key" != "dot_config_links" && "$submenu_key" != "music_links" ]]; then
    IFS=$'\n' sorted=($(sort <<<"${items[*]}"))
    unset IFS
    items=("${sorted[@]}")
  fi

  options+=("${items[@]}")
  printf '%s\n' "${options[@]}"
}

open_link() {
  local selected="$1"
  local value="${LINKS[$selected]:-}"

  local editor_command=""
  local file_path=""
  local rebuild_nixos=false

  if [[ "$value" == SUBMENU:* ]]; then
    push_to_stack "${value##*:}"
    run_submenu "${value##*:}" "${selected##*:}"
    return 0
  elif [[ -n "$value" ]]; then
    if [[ "$value" == program:* ]]; then
      ${value#program:} &
    elif [[ "$value" == sudo:nano:* ]]; then
      editor_command="kitty sudo nano"
      file_path="${value#sudo:nano:}"
      if [[ "$value" == *:REBUILD_NIXOS ]]; then
        file_path="${file_path%:REBUILD_NIXOS}"
        rebuild_nixos=true
      fi
    elif [[ "$value" == sudo:* ]]; then
      local cmd="${value#sudo:}"
      kitty sudo ${cmd%%:*} "${cmd#*:}" &
    elif [[ "$value" == thunar:* ]]; then
      thunar "${value#thunar:}" &
    elif [[ "$value" == mousepad:* ]]; then
      mousepad "${value#mousepad:}" &
    elif [[ "$value" == nano:* ]]; then
      editor_command="kitty nano"
      file_path="${value#nano:}"
    else
      xdg-open "$value" &
    fi

    if [[ -n "$editor_command" && -n "$file_path" ]]; then
      local original_hash=""
      if [[ -f "$file_path" ]]; then
        original_hash=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
      fi

      $editor_command "$file_path" &
      local editor_pid=$!

      wait "$editor_pid" 2>/dev/null
    fi
    return 0
  fi
  return 1
}

open_dot_config_item() {
  local selected="$1"
  local value="${LINKS[dot_config_links:$selected]:-}"

  if [[ "$selected" == "📟 Waybar" ]]; then
    push_to_stack "waybar_config_links"
    run_submenu "waybar_config_links" "Waybar"
    return 0
  fi

  [[ -z "$value" ]] && return 1

  if [[ -f "$value" ]]; then
    mousepad "$value" &
  else
    xdg-open "$value" &
  fi
  return 0
}

open_waybar_config_item() {
  local selected="$1"
  local value="${LINKS[waybar_config_links:$selected]:-}"

  if [[ "$selected" == "📦 Modules" ]]; then
    push_to_stack "waybar_script_modules"
    run_submenu "waybar_script_modules" "Waybar Modules"
    return 0
  fi

  [[ -z "$value" ]] && return 1

  if [[ -f "$value" ]]; then
    mousepad "$value" &
  else
    xdg-open "$value" &
  fi
  return 0
}

open_waybar_script_module() {
  local selected_with_emoji="$1"
  if [[ "$selected_with_emoji" == "📁 Open Scripts Folder" ]]; then
    thunar "/home/ls/.config/waybar/scripts" &
    return 0
  fi
  local selected_filename="${selected_with_emoji#* }"
  local script_path="/home/ls/.config/waybar/scripts/$selected_filename"
  if [[ -f "$script_path" ]]; then
    mousepad "$script_path" &
  else
    log_error "Script not found: $script_path"
  fi
}

run_submenu() {
  local submenu_key="$1"
  local prompt="$2"
  local wofi_args=(
    --dmenu
    --prompt "$prompt"
    --width 400
    --height $(( 100 + 50 * $(build_submenu_options "$submenu_key" | wc -l) ))
    --cache-file /dev/null
    --allow-markup
    --insensitive
    --matching fuzzy
    --style ~/.config/wofi/style.css
  )

  local selected
  selected=$(build_submenu_options "$submenu_key" | wofi "${wofi_args[@]}")

  [[ -z "$selected" ]] && return

  if [[ "$selected" == "⬅ Back" ]]; then
    pop_from_stack
    local prev_menu_key=$(peek_stack)
    if [[ -z "$prev_menu_key" ]]; then
      main
    elif [[ "$prev_menu_key" == "dot_config_links" ]]; then
      run_submenu "dot_config_links" ".config"
    elif [[ "$prev_menu_key" == "waybar_config_links" ]]; then
      run_submenu "waybar_config_links" "Waybar"
    else
      run_submenu "$prev_menu_key" "${prev_menu_key##*:}"
    fi
    return
  fi

  save_selection "$selected"

  case "$submenu_key" in
    favorite_links|nixos_links|fourchan_links|ai_links|media_links|social_links|program_links|nixos_modules)
      open_link "$submenu_key:$selected"
      ;;
    dot_config_links)
      open_dot_config_item "$selected"
      ;;
    waybar_config_links)
      open_waybar_config_item "$selected"
      ;;
    waybar_script_modules)
      open_waybar_script_module "$selected"
      ;;
    *)
      open_link "$submenu_key:$selected"
      ;;
  esac
}

main() {
  check_dependencies
  NAVIGATION_STACK=()

  local last_choice
  last_choice=$(get_last_selection)
  local options
  options=$(build_menu_options "$last_choice")

  local wofi_args=(
    --dmenu
    --prompt "󰍜 Links & Programs"
    --width 550
    --height 350
    --cache-file /dev/null
    --allow-markup
    --insensitive
    --matching fuzzy
    --style ~/.config/wofi/style.css
  )

  local selected
  selected=$(printf '%s\n' "$options" | wofi "${wofi_args[@]}")

  [[ -z "$selected" || "$selected" == "$SEPARATOR" ]] && exit 0

  save_selection "$selected"

  open_link "$selected" || {
    log_error "Selection '$selected' not recognized"
    exit 1
  }
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"