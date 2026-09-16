{ pkgs, lib, ... }:

let
  workspaceIconBar = pkgs.writeShellApplication {
    name = "workspace-icon-bar";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
      gawk
      i3
      jq
    ];
    text = ''
      cache_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      cache_file="$cache_dir/eww-desktop-icons"

      lowercase() {
        printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
      }

      build_icon_cache() {
        data_dirs="''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:$HOME/.nix-profile/share:/run/current-system/sw/share"
        : > "$cache_file"

        IFS=: read -r -a directories <<< "$data_dirs"
        for directory in "''${directories[@]}"; do
          applications="$directory/applications"
          [ -d "$applications" ] || continue

          while IFS= read -r -d "" desktop_file; do
            icon=$(sed -n 's/^Icon=//p' "$desktop_file" | head -n1)
            [ -n "$icon" ] || continue

            startup_class=$(sed -n 's/^StartupWMClass=//p' "$desktop_file" | head -n1)
            desktop_id=$(basename "$desktop_file" .desktop)

            for key in "$startup_class" "$desktop_id"; do
              [ -n "$key" ] || continue
              printf '%s\t%s\n' "$(lowercase "$key")" "$icon" >> "$cache_file"
            done
          done < <(find -L "$applications" -type f -name '*.desktop' -print0)
        done
      }

      render() {
        icon_map=$(jq -Rn '[inputs | split("\t") | select(length == 2) | {key: .[0], value: .[1]}] | from_entries' < "$cache_file")
        workspace_data=$(i3-msg -t get_workspaces -r)
        tree_data=$(i3-msg -t get_tree -r)

        jq -nc --argjson workspaces "$workspace_data" --argjson tree "$tree_data" --argjson icon_map "$icon_map" '
          def descendants: recurse(.nodes[]?, .floating_nodes[]?);
          [
            $workspaces[] |
            . as $workspace |
            {
              num: $workspace.num,
              name: $workspace.name,
              focused: $workspace.focused,
              urgent: $workspace.urgent,
              windows: [
                $tree |
                .. | objects |
                select(.type? == "workspace" and .num? == $workspace.num) |
                descendants |
                select(.window? != null) |
                (.window_properties.class? // "") as $class |
                ($class | ascii_downcase) as $key |
                {
                  class: $class,
                  icon: ($icon_map[$key] // "application-x-executable")
                }
              ]
            }
          ] | sort_by(.num)
        '
      }

      build_icon_cache
      render
      i3-msg -m -t subscribe '["workspace", "window"]' | while read -r _; do
        render
      done
    '';
  };

  codexbar = pkgs.writeShellApplication {
    name = "codexbar";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
      jq
    ];
    text = ''
      codex_home="''${CODEX_HOME:-$HOME/.codex}"
      session_dir="$codex_home/sessions"

      if [ ! -d "$session_dir" ]; then
        echo "CODEX --"
        exit 0
      fi

      session_file=$(find "$session_dir" -type f -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2- | sed -n '1p')

      if [ -z "$session_file" ]; then
        echo "CODEX --"
        exit 0
      fi

      snapshot=$(tail -n 500 "$session_file" | jq -r '
        select(.type == "event_msg" and .payload.type == "token_count")
        | [.payload.info.last_token_usage.total_tokens,
           .payload.info.model_context_window,
           .payload.rate_limits.primary.used_percent,
           .payload.rate_limits.secondary.used_percent]
        | @tsv' | tail -n1)

      if [ -z "$snapshot" ]; then
        echo "CODEX --"
        exit 0
      fi

      IFS=$'\t' read -r tokens context five_hour seven_day <<EOF
      $snapshot
      EOF

      if [ "''${context:-0}" -gt 0 ] 2>/dev/null; then
        context_pct=$((tokens * 100 / context))
      else
        context_pct=0
      fi

      if [ "''${tokens:-0}" -ge 1000 ] 2>/dev/null; then
        tokens_display="$((tokens / 1000))k"
      else
        tokens_display="''${tokens:-0}"
      fi

      printf 'CODEX CTX %s%% (%s) | PLAN 5h %.0f%% / 7d %.0f%%\n' "$context_pct" "$tokens_display" "''${five_hour:-0}" "''${seven_day:-0}"
    '';
  };

  backlightBar = pkgs.writeShellApplication {
    name = "backlight-bar";
    runtimeInputs = with pkgs; [
      brightnessctl
      coreutils
    ];
    text = ''
      brightnessctl -m | cut -d, -f4
    '';
  };

  volumeBar = pkgs.writeShellApplication {
    name = "volume-bar";
    runtimeInputs = with pkgs; [
      gawk
      gnugrep
      pulseaudio
    ];
    text = ''
      if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
        echo "󰖁 muted"
      else
        pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR == 1 { print "󰕾 " $5 }'
      fi
    '';
  };

  wlanBar = pkgs.writeShellApplication {
    name = "wlan-bar";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      networkmanager
    ];
    text = ''
      ssid=$(nmcli -t -f active,ssid dev wifi | sed -n 's/^yes://p' | head -n1)
      if [ -n "$ssid" ]; then
        printf '󰖩 %s\n' "$ssid"
      else
        echo "󰖪 disconnected"
      fi
    '';
  };

  batteryBar = pkgs.writeShellApplication {
    name = "battery-bar";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
      status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)

      case "$status" in
        Full) icon="󰁹" ;;
        Charging)
          case "$capacity" in
            100) icon="󰂅" ;;
            9[0-9]) icon="󰂋" ;;
            8[0-9]) icon="󰂊" ;;
            7[0-9]) icon="󰢞" ;;
            6[0-9]) icon="󰂉" ;;
            5[0-9]) icon="󰢝" ;;
            4[0-9]) icon="󰂈" ;;
            3[0-9]) icon="󰂇" ;;
            2[0-9]) icon="󰂆" ;;
            1[0-9]) icon="󰢜" ;;
            *) icon="󰢟" ;;
          esac
          ;;
        *)
          case "$capacity" in
            100) icon="󰁹" ;;
            9[0-9]) icon="󰂂" ;;
            8[0-9]) icon="󰂁" ;;
            7[0-9]) icon="󰂀" ;;
            6[0-9]) icon="󰁿" ;;
            5[0-9]) icon="󰁾" ;;
            4[0-9]) icon="󰁽" ;;
            3[0-9]) icon="󰁼" ;;
            2[0-9]) icon="󰁻" ;;
            1[0-9]) icon="󰁺" ;;
            *) icon="󰂎" ;;
          esac
          ;;
      esac

      printf '%s %s%%\n' "$icon" "''${capacity:---}"
    '';
  };
in
{
  home.packages = [
    pkgs.eww
    pkgs.networkmanagerapplet
    workspaceIconBar
    codexbar
    backlightBar
    volumeBar
    wlanBar
    batteryBar
  ];

  xdg.configFile."eww/eww.yuck".text = builtins.replaceStrings
    [
      "@workspaceIconBar@"
      "@backlightBar@"
      "@volumeBar@"
      "@wlanBar@"
      "@batteryBar@"
      "@codexbar@"
    ]
    [
      "${workspaceIconBar}/bin/workspace-icon-bar"
      "${backlightBar}/bin/backlight-bar"
      "${volumeBar}/bin/volume-bar"
      "${wlanBar}/bin/wlan-bar"
      "${batteryBar}/bin/battery-bar"
      "${codexbar}/bin/codexbar"
    ]
    (builtins.readFile ./eww/eww.yuck);
  xdg.configFile."eww/eww.scss".source = ./eww/eww.scss;

  systemd.user.services.eww = {
    Unit = {
      Description = "Eww bar";
      PartOf = [ "i3-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.eww}/bin/eww daemon";
      ExecStartPost = "${pkgs.eww}/bin/eww open bar";
      ExecStop = "${pkgs.eww}/bin/eww kill";
      RemainAfterExit = true;
      Environment = [
        "PATH=${lib.makeBinPath [
          workspaceIconBar
          codexbar
          backlightBar
          volumeBar
          wlanBar
          batteryBar
          pkgs.bash
          pkgs.coreutils
          pkgs.i3
        ]}"
      ];
    };
    Install.WantedBy = [ "i3-session.target" ];
  };
}
