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
      imagemagick
      jq
    ];
    text = ''
      cache_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      cache_file="$cache_dir/eww-desktop-icons"
      icon_file="$cache_dir/eww-icon-files"
      scaled_dir="$cache_dir/eww-scaled-icons"

      lowercase() {
        printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
      }

      build_icon_cache() {
        mkdir -p "$scaled_dir"
        data_dirs="''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:$HOME/.nix-profile/share:/run/current-system/sw/share"
        : > "$cache_file"
        : > "$icon_file"

        IFS=: read -r -a directories <<< "$data_dirs"
        for directory in "''${directories[@]}"; do
          find -L "$directory/icons" "$directory/pixmaps" -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.xpm' \) -printf '%f\t%p\n' 2>/dev/null >> "$icon_file" || true
        done

        for directory in "''${directories[@]}"; do
          applications="$directory/applications"
          [ -d "$applications" ] || continue

          while IFS= read -r -d "" desktop_file; do
            icon=$(sed -n 's/^Icon=//p' "$desktop_file" | head -n1)
            [ -n "$icon" ] || continue

            if [[ "$icon" = /* ]] && [ -f "$icon" ]; then
              icon_path="$icon"
            else
              icon_path=$(awk -F '\t' -v icon="$(lowercase "$icon")" '
                tolower($1) == icon ".png" || tolower($1) == icon ".svg" || tolower($1) == icon ".xpm" {
                  print $2
                  exit
                }
              ' "$icon_file")
            fi

            [ -n "$icon_path" ] || continue

            startup_class=$(sed -n 's/^StartupWMClass=//p' "$desktop_file" | head -n1)
            desktop_id=$(basename "$desktop_file" .desktop)

            for key in "$startup_class" "$desktop_id"; do
              [ -n "$key" ] || continue
              printf '%s\t%s\t%s\n' "$(lowercase "$key")" "$icon" "$icon_path" >> "$cache_file"
            done
          done < <(find -L "$applications" -type f -name '*.desktop' -print0)
        done

        fallback_path=$(awk -F '\t' '
          tolower($1) == "application-x-executable.png" || tolower($1) == "application-x-executable.svg" {
            print $2
            exit
          }
        ' "$icon_file")
        printf '__fallback__\tapplication-x-executable\t%s\n' "$fallback_path" >> "$cache_file"
      }

      scale_icon() {
        source_path="$1"
        cache_key=$(printf '%s' "$source_path" | sha256sum | cut -d ' ' -f1)
        scaled_path="$scaled_dir/$cache_key.png"

        if [ ! -f "$scaled_path" ]; then
          magick "$source_path" -background none -thumbnail '16x16>' -gravity center -extent 16x16 "$scaled_path"
        fi

        printf '%s' "$scaled_path"
      }

      active_icon_map() {
        tree_data="$1"
        active_file="$cache_dir/eww-active-icons"
        : > "$active_file"

        while IFS= read -r key; do
          entry=$(awk -F '\t' -v key="$key" '$1 == key { print; exit }' "$cache_file")
          [ -n "$entry" ] || entry=$(awk -F '\t' '$1 == "__fallback__" { print; exit }' "$cache_file")
          icon_name=$(printf '%s' "$entry" | cut -f2)
          source_path=$(printf '%s' "$entry" | cut -f3)
          [ -f "$source_path" ] || continue
          printf '%s\t%s\t%s\n' "$key" "$icon_name" "$(scale_icon "$source_path")" >> "$active_file"
        done < <(jq -r '[.. | objects | select(.window? != null) | (.window_properties.class? // "") | ascii_downcase | select(length > 0)] | unique[]' <<< "$tree_data")

        fallback=$(awk -F '\t' '$1 == "__fallback__" { print; exit }' "$cache_file")
        fallback_name=$(printf '%s' "$fallback" | cut -f2)
        fallback_source=$(printf '%s' "$fallback" | cut -f3)
        if [ -f "$fallback_source" ]; then
          printf '__fallback__\t%s\t%s\n' "$fallback_name" "$(scale_icon "$fallback_source")" >> "$active_file"
        fi

        jq -Rn '[inputs | split("\t") | select(length == 3) | {key: .[0], value: {name: .[1], path: .[2]}}] | from_entries' < "$active_file"
      }

      render() {
        workspace_data=$(i3-msg -t get_workspaces -r)
        tree_data=$(i3-msg -t get_tree -r)
        icon_map=$(active_icon_map "$tree_data")

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
                  icon: (($icon_map[$key] // $icon_map.__fallback__).name),
                  icon_path: (($icon_map[$key] // $icon_map.__fallback__).path)
                }
              ]
            }
          ] | sort_by(.num)
        '
      }

      build_icon_cache
      previous=""
      current=$(render)
      printf '%s\n' "$current"
      previous="$current"
      i3-msg -m -t subscribe '["workspace", "window"]' | while read -r _; do
        current=$(render)
        if [ "$current" != "$previous" ]; then
          printf '%s\n' "$current"
          previous="$current"
        fi
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
        echo '{"context":0,"tokens":"--","five_hour":0,"seven_day":0}'
        exit 0
      fi

      session_file=$(find "$session_dir" -type f -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2- | sed -n '1p')

      if [ -z "$session_file" ]; then
        echo '{"context":0,"tokens":"--","five_hour":0,"seven_day":0}'
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
        echo '{"context":0,"tokens":"--","five_hour":0,"seven_day":0}'
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

      jq -nc \
        --argjson context "$context_pct" \
        --arg tokens "$tokens_display" \
        --argjson five_hour "''${five_hour:-0}" \
        --argjson seven_day "''${seven_day:-0}" \
        '{context: $context, tokens: $tokens, five_hour: $five_hour, seven_day: $seven_day}'
    '';
  };

  backlightBar = pkgs.writeShellApplication {
    name = "backlight-bar";
    runtimeInputs = with pkgs; [
      brightnessctl
      coreutils
      inotify-tools
    ];
    text = ''
      emit() {
        brightnessctl -m | cut -d, -f4 | tr -d '%'
      }

      device=$(brightnessctl -m | cut -d, -f1)
      brightness_file="/sys/class/backlight/$device/brightness"
      emit
      inotifywait -m -q -e modify "$brightness_file" | while read -r _; do
        emit
      done
    '';
  };

  volumeBar = pkgs.writeShellApplication {
    name = "volume-bar";
    runtimeInputs = with pkgs; [
      gawk
      gnugrep
      jq
      pulseaudio
    ];
    text = ''
      emit() {
        percent=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR == 1 { gsub(/%/, "", $5); print $5 }')
        if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
          muted=true
          icon="󰖁"
        else
          muted=false
          if [ "$percent" -ge 67 ]; then
            icon="󰕾"
          elif [ "$percent" -ge 34 ]; then
            icon="󰖀"
          elif [ "$percent" -gt 0 ]; then
            icon="󰕿"
          else
            icon="󰝟"
          fi
        fi

        jq -nc --arg icon "$icon" --argjson percent "$percent" --argjson muted "$muted" '{icon: $icon, percent: $percent, muted: $muted}'
      }

      emit
      pactl subscribe | while read -r event; do
        case "$event" in
          *"on sink"*|*"on server"*) emit ;;
        esac
      done
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

  wifiNetworks = pkgs.writeShellApplication {
    name = "wifi-networks";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      jq
      networkmanager
    ];
    text = ''
      enabled=$(nmcli -t -f WIFI general 2>/dev/null || printf disabled)
      active_ssid=$(nmcli -t -f ACTIVE,SSID device wifi list --rescan no 2>/dev/null | sed -n 's/^yes://p' | head -n1)
      active_ssid=$(printf '%s' "$active_ssid" | sed 's/\\:/:/g; s/\\\\/\\/g')

      networks=$(
        declare -A seen=()
        while IFS=: read -r active signal security ssid; do
          ssid=$(printf '%s' "$ssid" | sed 's/\\:/:/g; s/\\\\/\\/g')
          [ -n "$ssid" ] || continue
          [ -z "''${seen[$ssid]+x}" ] || continue
          seen[$ssid]=1

          if [ "$active" = yes ]; then
            connected=true
          else
            connected=false
          fi

          if [ "$security" = "--" ] || [ -z "$security" ]; then
            secured=false
          else
            secured=true
          fi

          encoded=$(printf '%s' "$ssid" | base64 -w0)
          jq -nc \
            --arg ssid "$ssid" \
            --arg id "$encoded" \
            --arg security "$security" \
            --argjson signal "''${signal:-0}" \
            --argjson connected "$connected" \
            --argjson secured "$secured" \
            '{ssid: $ssid, id: $id, signal: $signal, security: $security, connected: $connected, secured: $secured}'
        done < <(nmcli -t -f ACTIVE,SIGNAL,SECURITY,SSID device wifi list --rescan auto 2>/dev/null)
      )

      if [ -n "$networks" ]; then
        network_array=$(printf '%s\n' "$networks" | jq -sc '.[0:12]')
      else
        network_array='[]'
      fi

      if [ "$enabled" = enabled ]; then
        enabled_json=true
      else
        enabled_json=false
      fi

      jq -nc \
        --argjson enabled "$enabled_json" \
        --arg connected "$active_ssid" \
        --argjson networks "$network_array" \
        '{enabled: $enabled, connected: $connected, networks: $networks}'
    '';
  };

  wifiAction = pkgs.writeShellApplication {
    name = "wifi-action";
    runtimeInputs = with pkgs; [
      coreutils
      eww
      gawk
      libnotify
      networkmanager
      networkmanagerapplet
    ];
    text = ''
      action="''${1:-}"

      case "$action" in
        toggle)
          if [ "$(nmcli -t -f WIFI general)" = enabled ]; then
            nmcli radio wifi off
          else
            nmcli radio wifi on
          fi
          ;;
        rescan)
          nmcli device wifi rescan || true
          ;;
        disconnect)
          device=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }')
          [ -z "$device" ] || nmcli device disconnect "$device"
          ;;
        connect)
          ssid=$(printf '%s' "''${2:-}" | base64 --decode)
          if ! nmcli --wait 15 device wifi connect "$ssid"; then
            notify-send "Wi-Fi connection" "Credentials or additional configuration are required for $ssid"
            nm-connection-editor >/dev/null 2>&1 &
          fi
          ;;
        settings)
          nm-connection-editor >/dev/null 2>&1 &
          ;;
      esac

      eww poll wifi_networks >/dev/null 2>&1 || true
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

  brightnessAction = pkgs.writeShellApplication {
    name = "brightness-action";
    runtimeInputs = [ pkgs.brightnessctl ];
    text = ''
      case "''${1:-}" in
        up) brightnessctl set 5%+ ;;
        down) brightnessctl set 5%- ;;
      esac
    '';
  };

  volumeAction = pkgs.writeShellApplication {
    name = "volume-action";
    runtimeInputs = [ pkgs.pulseaudio ];
    text = ''
      case "''${1:-}" in
        toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
        down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
      esac
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
    brightnessAction
    volumeAction
    wifiNetworks
    wifiAction
  ];

  xdg.configFile."eww/eww.yuck".text = builtins.replaceStrings
    [
      "@workspaceIconBar@"
      "@backlightBar@"
      "@volumeBar@"
      "@wlanBar@"
      "@batteryBar@"
      "@codexbar@"
      "@brightnessAction@"
      "@volumeAction@"
      "@networkEditor@"
      "@wifiNetworks@"
      "@wifiAction@"
      "@wifiToggle@"
    ]
    [
      "${workspaceIconBar}/bin/workspace-icon-bar"
      "${backlightBar}/bin/backlight-bar"
      "${volumeBar}/bin/volume-bar"
      "${wlanBar}/bin/wlan-bar"
      "${batteryBar}/bin/battery-bar"
      "${codexbar}/bin/codexbar"
      "${brightnessAction}/bin/brightness-action"
      "${volumeAction}/bin/volume-action"
      "${pkgs.networkmanagerapplet}/bin/nm-connection-editor"
      "${wifiNetworks}/bin/wifi-networks"
      "${wifiAction}/bin/wifi-action"
      "${pkgs.eww}/bin/eww open --toggle wifi-panel"
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
          brightnessAction
          volumeAction
          wifiNetworks
          wifiAction
          pkgs.bash
          pkgs.coreutils
          pkgs.i3
        ]}"
      ];
    };
    Install.WantedBy = [ "i3-session.target" ];
  };
}
