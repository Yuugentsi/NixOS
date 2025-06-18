function reboot
    echo "Reiniciando o sistema..."
    pkill hyprland
    sleep 1
    sudo systemctl reboot
end
