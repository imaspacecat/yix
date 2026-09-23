{ pkgs, ... }:

{
  home.username = "spacecat";
  home.homeDirectory = "/home/spacecat";
  home.packages = with pkgs; [
    fastfetch
    btop
    xclip
    maim
    jq
    keepassxc
    brightnessctl
    tree
    ripgrep
    fd
    file
    feh
    gimp
    discord-ptb
    usbutils
  ];

  home.stateVersion = "26.05";
}
