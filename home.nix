{ pkgs, ... }:

{
  home.username = "spacecat";
  home.homeDirectory = "/home/spacecat";
  home.packages = with pkgs; [
    fastfetch
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

  programs.btop = {
    enable = true;
    settings.proc_tree = true;
  };

  home.stateVersion = "26.05";
}
