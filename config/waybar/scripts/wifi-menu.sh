#!/usr/bin/env bash

config="$HOME/.config/wofi/config"

options=$(
  echo "Manual Entry"
  echo "Disable Wi-Fi"
)

option_disabled="Enable Wi-Fi"

wifi_status=$(nmcli -fields WIFI g)

set_dns() {
  local ssid="$1"
  local connection_name="$ssid"
  if nmcli -g NAME connection | grep -qw "$ssid"; then
    nmcli connection modify "$connection_name" ipv4.dns "1.1.1.1,1.0.0.1"
    nmcli connection modify "$connection_name" ipv4.ignore-auto-dns yes
    nmcli connection up "$connection_name"
  fi
}

while true; do
  wifi_list() {
    nmcli --fields "SECURITY,SSID" device wifi list |
      tail -n +2 |
      sed 's/  */ /g' |
      sed -E "s/WPA*.?\S/󰤪 /g" |
      sed "s/^--/󰤨 /g" |
      sed "s/󰤪  󰤪/󰤪/g" |
      sed "/--/d" |
      awk '!seen[$0]++'
  }

  case "$wifi_status" in
  *"enabled"*)
    selected_option=$( (echo "$options"; wifi_list) | wofi --dmenu --prompt=" " --lines=10) || exit
    ;;
  *"disabled"*)
    selected_option=$(echo "$option_disabled" | wofi --dmenu --prompt="󰤮" --lines=1) || exit
    ;;
  esac

  read -r selected_ssid <<<"${selected_option#???}"

  case "$selected_option" in
  "")
    exit
    ;;
  "Enable Wi-Fi")
    notify-send "Scanning for networks..." -i "package-installed-outdated"
    nmcli radio wifi on
    nmcli device wifi rescan
    sleep 3
    wifi_status=$(nmcli -fields WIFI g)
    ;;
  "Disable Wi-Fi")
    notify-send "Wi-Fi Disabled" -i "package-broken"
    nmcli radio wifi off
    exit
    ;;
  "Manual Entry")
    manual_ssid=$(wofi --dmenu --prompt="Enter SSID:") || exit
    if [ -z "$manual_ssid" ]; then exit; fi
    wifi_password=$(wofi --dmenu --prompt="Enter Password:" --password) || exit
    if [ -z "$wifi_password" ]; then
      if nmcli device wifi connect "$manual_ssid" | grep -q "successfully"; then
        set_dns "$manual_ssid"
        notify-send "Connected to \"$manual_ssid\" with DNS 1.1.1.1." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$manual_ssid\"." -i "package-broken"
      fi
    else
      if nmcli device wifi connect "$manual_ssid" password "$wifi_password" | grep -q "successfully"; then
        set_dns "$manual_ssid"
        notify-send "Connected to \"$manual_ssid\" with DNS 1.1.1.1." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$manual_ssid\"." -i "package-broken"
      fi
    fi
    ;;
  *)
    saved_connections=$(nmcli -g NAME connection)
    if echo "$saved_connections" | grep -qw "$selected_ssid"; then
      if nmcli connection up id "$selected_ssid" | grep -q "successfully"; then
        set_dns "$selected_ssid"
        notify-send "Connected to \"$selected_ssid\" with DNS 1.1.1.1." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$selected_ssid\"." -i "package-broken"
      fi
    else
      if [[ "$selected_option" =~ ^"󰤪" ]]; then
        wifi_password=$(wofi --dmenu --prompt="Enter Password:" --password) || exit
      fi
      if nmcli device wifi connect "$selected_ssid" password "$wifi_password" | grep -q "successfully"; then
        set_dns "$selected_ssid"
        notify-send "Connected to \"$selected_ssid\" with DNS 1.1.1.1." -i "package-installed-outdated"
        exit
      else
        notify-send "Failed to connect to \"$selected_ssid\"." -i "package-broken"
      fi
    fi
    ;;
  esac
done