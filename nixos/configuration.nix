{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/packages.nix
    ./modules/zram.nix
    ./modules/locale.nix
    ./modules/fonts.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  environment.variables.XCURSOR_SIZE = "100";

  users.users.ls = {
    isNormalUser = true;
    description = "ls";
    extraGroups = [ "networkmanager" "wheel" "disk" ];
    packages = with pkgs; [];
    shell = pkgs.fish;
  };

  services.printing.enable = true;
  services.dbus.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  security.polkit.enable = true;

  services.xserver = {
    enable = true;
    displayManager.lightdm.greeters.gtk.enable = true;
    xkb = {
      layout = "br";
      variant = "thinkpad";
    };
  };

  services.libinput.enable = true;

  services.displayManager.sessionPackages = with pkgs; [ hyprland ];
  services.displayManager.defaultSession = "hyprland";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    configPackages = [ pkgs.xdg-desktop-portal-wlr ];
  };

  programs.fish.enable = true;
  programs.nm-applet.enable = true;
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix.settings.auto-optimise-store = true;
  nix.extraOptions = ''
    auto-optimise-store = true
    keep-outputs = true
    keep-derivations = true
  '';

  services.tlp.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "25.05";
}
