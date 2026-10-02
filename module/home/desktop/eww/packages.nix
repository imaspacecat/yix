{ pkgs, ... }:

{
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
      session_dir="''${CODEX_HOME:-$HOME/.codex}/sessions"
      {
        if [ -d "$session_dir" ]; then
          session_file=$(find "$session_dir" -type f -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2- | sed -n '1p')
          if [ -n "$session_file" ]; then
            tail -n 500 "$session_file"
          fi
        fi
      } | jq -sc '
        map(select(.type == "event_msg" and .payload.type == "token_count"))
        | last | .payload as $snapshot
        | if $snapshot == null then
            {context: 0, tokens: "--", five_hour: 0, seven_day: 0}
          else
            ($snapshot.info.last_token_usage.total_tokens // 0) as $tokens
            | ($snapshot.info.model_context_window // 0) as $window
            | {
                context: (if $window > 0 then ($tokens * 100 / $window | floor) else 0 end),
                tokens: (if $tokens >= 1000 then "\($tokens / 1000 | floor)k" else ($tokens | tostring) end),
                five_hour: ($snapshot.rate_limits.primary.used_percent // 0),
                seven_day: ($snapshot.rate_limits.secondary.used_percent // 0)
              }
          end'
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
        volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null) || return 1
        percent=$(awk 'NR == 1 { gsub(/%/, "", $5); print $5 }' <<< "$volume")
        mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null) || return 1

        if grep -q yes <<< "$mute"; then
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

      while :; do
        emit || true
        pactl subscribe 2>/dev/null | while read -r event; do
          case "$event" in
            *"on sink"*|*"on server"*) emit || true ;;
          esac
        done || true
        sleep 1
      done
    '';
  };

  batteryBar = pkgs.writeShellApplication {
    name = "battery-bar";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if ! capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null); then
        echo "󰂎 --"
        exit 0
      fi
      status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || true)

      if [ "$status" = Charging ]; then
        icon="󰂅"
      elif [ "$capacity" -ge 90 ]; then
        icon="󰁹"
      elif [ "$capacity" -ge 50 ]; then
        icon="󰁾"
      elif [ "$capacity" -ge 20 ]; then
        icon="󰁻"
      else
        icon="󰂎"
      fi

      printf '%s %s%%\n' "$icon" "$capacity"
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
}
