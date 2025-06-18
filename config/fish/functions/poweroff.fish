function poweroff
    echo "Shutting down the system..."
    pkill hyprland
    sleep 1
    sudo systemctl poweroff
end
