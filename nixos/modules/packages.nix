{ config, pkgs, ... }:

{
  options = {};

  config = {
    environment.systemPackages = with pkgs; [
      #Core
      fish
      git
      kitty
      unzip
      zip
      file-roller
      android-tools
      brightnessctl
      wl-clipboard
      xclip

      # 🖥️ Desktop
      hyprland
      hyprsunset
      waybar
      wofi
      swaybg
      nwg-look
      lightdm-gtk-greeter
      grim
      slurp

      #XFCE
      xfce.xfdesktop
      xfce.thunar
      xfce.thunar-volman
      xfce.mousepad

      #Media
      playerctl
      pulseaudio
      yt-dlp
      gallery-dl
      dunst
      libnotify
      geoclue2

      #Apps
      mpv
      telegram-desktop
      viewnior
      materialgram
      librewolf
      keepassxc
    ];
  };
}
