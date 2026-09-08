{ pkgs, lib, ... }:

let
  nextFreeWs = pkgs.writeShellApplication {
    name = "i3-next-free-workspace";
    runtimeInputs = with pkgs; [
      coreutils
      i3
      jq
    ];
    text = ''
      i3-msg -t get_workspaces | jq '[.[] | select(.num != -1).num] as $ws | (range(1; 20) | select(. as $n | ($ws | contains([$n]) | not)))' | head -n1
    '';
  };

  moveNewWs = pkgs.writeShellApplication {
    name = "i3-move-new-workspace";
    runtimeInputs = [ pkgs.i3 ];
    text = ''
      ws=$(${nextFreeWs}/bin/i3-next-free-workspace)
      i3-msg "move container to workspace $ws; workspace $ws"
    '';
  };

  focusNewWs = pkgs.writeShellApplication {
    name = "i3-focus-new-workspace";
    runtimeInputs = [ pkgs.i3 ];
    text = ''
      ws=$(${nextFreeWs}/bin/i3-next-free-workspace)
      i3-msg "workspace $ws"
    '';
  };

  moveNextWs = pkgs.writeShellApplication {
    name = "i3-move-next-workspace";
    runtimeInputs = with pkgs; [
      i3
      jq
    ];
    text = ''
      workspaces=$(i3-msg -t get_workspaces | jq -c '[.[] | select(.num != -1)] | sort_by(.num)')
      current=$(echo "$workspaces" | jq '.[] | select(.focused == true).num')
      next=$(echo "$workspaces" | jq --argjson cur "$current" '[.[] | select(.num > $cur).num] | first')

      if [ "$next" = "null" ] || [ -z "$next" ]; then
        next=$(echo "$workspaces" | jq '.[0].num')
      fi

      i3-msg "move container to workspace $next; workspace $next"
    '';
  };

  movePrevWs = pkgs.writeShellApplication {
    name = "i3-move-previous-workspace";
    runtimeInputs = with pkgs; [
      i3
      jq
    ];
    text = ''
      workspaces=$(i3-msg -t get_workspaces | jq -c '[.[] | select(.num != -1)] | sort_by(.num)')
      current=$(echo "$workspaces" | jq '.[] | select(.focused == true).num')
      prev=$(echo "$workspaces" | jq --argjson cur "$current" '[.[] | select(.num < $cur).num] | last')

      if [ "$prev" = "null" ] || [ -z "$prev" ]; then
        prev=$(echo "$workspaces" | jq '.[-1].num')
      fi

      i3-msg "move container to workspace $prev; workspace $prev"
    '';
  };
in
{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      terminal = "alacritty";
      modifier = "Mod4";

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
          background = "#444444";
          text = "#ffffff";
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
          command = "feh --bg-max /home/spacecat/Downloads/totoro2.webp";
          always = true;
          notification = false;
        }
        {
          command = "systemctl --user restart polybar.service";
          always = true;
          notification = false;
        }
      ];

      keybindings =
        let
          mod = "Mod4";
        in
        lib.mkOptionDefault {
          "${mod}+t" = "exec alacritty";
          "${mod}+c" = "exec urxvt -name yazi -e yazi";
          "${mod}+d" = "exec rofi -show drun";
          "${mod}+b" = "exec bluetooth-rofi";
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
          "${mod}+f" = "fullscreen toggle";

          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";

          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";

          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+e" = "exec i3-msg exit";

          "${mod}+Shift+s" = "exec maim -s | xclip -selection clipboard -t image/png";

          "Ctrl+${mod}+Left" = "workspace prev";
          "Ctrl+${mod}+Right" = "workspace next";

          "Ctrl+Shift+${mod}+Left" = "exec ${movePrevWs}/bin/i3-move-previous-workspace";
          "Ctrl+Shift+${mod}+Right" = "exec ${moveNextWs}/bin/i3-move-next-workspace";

          "${mod}+Shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";

          "${mod}+Shift+plus" = "exec ${moveNewWs}/bin/i3-move-new-workspace";

          "${mod}+plus" = "exec ${focusNewWs}/bin/i3-focus-new-workspace";

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
