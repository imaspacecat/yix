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
    (writeShellApplication {
      name = "ambient-microphone";
      runtimeInputs = [ pulseaudio ffmpeg-headless pipewire systemd ];
      text = builtins.readFile ./scripts/ambient-microphone;
    })
  ];

  programs.btop = {
    enable = true;
    settings.proc_tree = true;
  };

  home.stateVersion = "26.05";
}
