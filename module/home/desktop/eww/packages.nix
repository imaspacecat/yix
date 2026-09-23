{ pkgs, ... }:

let
  workspaceIconBar = pkgs.writeShellApplication {
    name = "workspace-icon-bar";
    runtimeInputs = with pkgs; [
      i3
      jq
    ];
    text = ''
      emit() {
        i3-msg -t get_workspaces -r | jq -c '[.[] | {num, name, focused, urgent}] | sort_by(.num)'
      }

      while :; do
        emit || true
        while read -r _; do
          emit || true
        done < <(i3-msg -m -t subscribe '["workspace"]' 2>/dev/null)
        sleep 1
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
      gawk
      gnused
      jq
      networkmanager
    ];
    text = ''
      enabled=$(nmcli -t -f WIFI general 2>/dev/null || printf disabled)
      wifi_device=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')
      active_ssid=$(nmcli -g GENERAL.CONNECTION device show "$wifi_device" 2>/dev/null || true)
      [ "$active_ssid" != "--" ] || active_ssid=""

      networks=$(
        declare -A seen=()
        while IFS=: read -r _ signal security ssid; do
          ssid=$(printf '%s' "$ssid" | sed 's/\\:/:/g; s/\\\\/\\/g')
          [ -n "$ssid" ] || continue
          [ -z "''${seen[$ssid]+x}" ] || continue
          seen[$ssid]=1

          if [ "$ssid" = "$active_ssid" ]; then
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
          security_id=$(printf '%s' "$security" | base64 -w0)
          jq -nc \
            --arg ssid "$ssid" \
            --arg id "$encoded" \
            --arg security "$security" \
            --arg security_id "$security_id" \
            --argjson signal "''${signal:-0}" \
            --argjson connected "$connected" \
            --argjson secured "$secured" \
            '{ssid: $ssid, id: $id, signal: $signal, security: $security, security_id: $security_id, connected: $connected, secured: $secured}'
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
      gnugrep
      libnotify
      networkmanager
      networkmanagerapplet
      zenity
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
          security=$(printf '%s' "''${3:-}" | base64 --decode)
          if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
            nmcli --wait 20 connection up id "$ssid"
          elif [[ "$security" == *802.1X* ]]; then
            eww close wifi-panel 2>/dev/null || true
            eww close panel-backdrop 2>/dev/null || true
            notify-send "Wi-Fi connection" "$ssid requires enterprise network settings"
            nm-connection-editor >/dev/null 2>&1 &
          elif [ -n "$security" ]; then
            eww close wifi-panel 2>/dev/null || true
            eww close panel-backdrop 2>/dev/null || true
            if password=$(zenity --password --title="Connect to $ssid" --text="Enter the password for $ssid"); then
              nmcli --wait 20 device wifi connect "$ssid" password "$password"
            fi
          else
            nmcli --wait 20 device wifi connect "$ssid"
          fi
          ;;
        settings)
          nm-connection-editor >/dev/null 2>&1 &
          ;;
      esac

      eww poll wifi_networks >/dev/null 2>&1 || true
    '';
  };

  panelClose = pkgs.writeShellApplication {
    name = "panel-close";
    runtimeInputs = with pkgs; [
      eww
      gnugrep
    ];
    text = ''
      active=$(eww active-windows)
      for window in wifi-panel ram-panel panel-backdrop; do
        if grep -q "^$window:" <<< "$active"; then
          eww close "$window"
        fi
      done
    '';
  };

  panelToggle = pkgs.writeShellApplication {
    name = "panel-toggle";
    runtimeInputs = with pkgs; [
      coreutils
      eww
      gnugrep
      gnused
      xdotool
    ];
    text = ''
      panel="$1"
      width="$2"
      was_open=false

      if eww active-windows | grep -q "^$panel:"; then
        was_open=true
      fi

      ${panelClose}/bin/panel-close
      if [ "$was_open" = true ]; then
        exit 0
      fi

      pointer_x=$(xdotool getmouselocation --shell | sed -n 's/^X=//p')
      screen_width=$(xdotool getdisplaygeometry | cut -d ' ' -f1)
      left=$((pointer_x - width / 2))
      [ "$left" -ge 8 ] || left=8
      max_left=$((screen_width - width - 8))
      [ "$left" -le "$max_left" ] || left="$max_left"

      eww open panel-backdrop
      eww open "$panel" --arg x="$left"
    '';
  };

  ramProcesses = pkgs.writeShellApplication {
    name = "ram-processes";
    runtimeInputs = with pkgs; [
      gnused
      jq
      procps
    ];
    text = ''
      ps -eo pid=,rss=,comm= --sort=-rss | sed -n '1,10p' | while read -r pid rss name; do
        jq -nc --argjson pid "$pid" --arg name "$name" --argjson mib "$((rss / 1024))" '{pid: $pid, name: $name, mib: $mib}'
      done | jq -sc 'if length == 0 then [] else .[0].mib as $max | map(. + {heat: ((.mib * 100 / $max) | floor)}) end'
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
  inherit
    workspaceIconBar
    codexbar
    backlightBar
    volumeBar
    wlanBar
    wifiNetworks
    wifiAction
    panelClose
    panelToggle
    ramProcesses
    batteryBar
    brightnessAction
    volumeAction
    ;
}
