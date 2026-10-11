{ pkgs, lib, ... }:

let
  mod = "Mod4";
  wallpaper = "/home/spacecat/Downloads/totoro.jpeg";

  focusedTitle = pkgs.writeShellApplication {
    name = "i3-focused-title";
    runtimeInputs = with pkgs; [ i3 jq util-linux ];
    text = builtins.readFile ../../../scripts/i3-focused-title;
  };

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    runtimeInputs = with pkgs; [
      coreutils
      imagemagick
      xdpyinfo
      gawk
      i3lock
    ];
    runtimeEnv.WALLPAPER = wallpaper;
    text = builtins.readFile ../../../scripts/lock-screen;
  };

  sessionMenu = pkgs.writeShellApplication {
    name = "session-menu";
    runtimeInputs = with pkgs; [
      rofi
      i3
      systemd
      lockScreen
    ];
    text = builtins.readFile ../../../scripts/session-menu;
  };

  workspace = pkgs.writeShellApplication {
    name = "i3-workspace";
    runtimeInputs = with pkgs; [ i3 jq ];
    text = builtins.readFile ../../../scripts/i3-workspace;
  };

in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      terminal = "alacritty";
      modifier = mod;

      gaps = {
        inner = 8;
        outer = 2;
      };

      fonts = {
        names = [ "JetBrainsMono Nerd Font" ];
        size = 10.0;
      };

      window = {
        border = 2;
        titlebar = true;
      };

      colors = {
        background = "#222222";
        focused = {
          border = "#444444";
          background = "#ffffff";
          text = "#222222";
          indicator = "#ffffff";
          childBorder = "#444444";
        };
        focusedInactive = {
          border = "#444444";
          background = "#222222";
          text = "#ffffff";
          indicator = "#222222";
          childBorder = "#444444";
        };
        unfocused = {
          border = "#444444";
          background = "#222222";
          text = "#ffffff";
          indicator = "#222222";
          childBorder = "#444444";
        };
        urgent = {
          border = "#ffffff";
          background = "#444444";
          text = "#ffffff";
          indicator = "#ffffff";
          childBorder = "#ffffff";
        };
        placeholder = {
          border = "#444444";
          background = "#222222";
          text = "#ffffff";
          indicator = "#222222";
          childBorder = "#444444";
        };
      };

      startup = [
        {
          command = "${focusedTitle}/bin/i3-focused-title";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.feh}/bin/feh --bg-fill ${lib.escapeShellArg wallpaper}";
          always = true;
          notification = false;
        }
        {
          command = "systemctl --user restart polybar.service";
          always = true;
          notification = false;
        }
      ];

      keybindings = lib.mkOptionDefault {
        "${mod}+t" = "exec alacritty";
        "${mod}+c" = "exec urxvt -name yazi -e yazi";
        "${mod}+d" = "exec rofi -show drun";
        "${mod}+b" = "exec rofi-bluetooth";
        "${mod}+Escape" = "exec ${sessionMenu}/bin/session-menu";
        "${mod}+q" = "kill";

        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";

        "${mod}+x" = "split h";
        "${mod}+z" = "split v";

        "${mod}+Shift+e" = "exec i3-msg exit";

        "${mod}+Shift+s" = "exec screenshot";
        "Ctrl+${mod}+Shift+s" = "exec screenshot --full";

        "Ctrl+${mod}+Left" = "workspace prev";
        "Ctrl+${mod}+Right" = "workspace next";

        "Ctrl+Shift+${mod}+Left" = "exec ${workspace}/bin/i3-workspace previous --move";
        "Ctrl+Shift+${mod}+Right" = "exec ${workspace}/bin/i3-workspace next --move";

        "${mod}+Shift+plus" = "exec ${workspace}/bin/i3-workspace new --move";

        "${mod}+plus" = "exec ${workspace}/bin/i3-workspace new";

        "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

        "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      };

      bars = [ ];
    };

    extraConfig = ''
      for_window [class="discord"] move scratchpad; scratchpad show
      for_window [class="URxvt" instance="yazi"] floating enable
    '';
  };
}
