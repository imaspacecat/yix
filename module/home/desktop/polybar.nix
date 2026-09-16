{ pkgs, ... }:

let
  codexbar = pkgs.writeShellScriptBin "codexbar" ''
    # Codex writes token and rate-limit snapshots to its local session JSONL.
    codex_home="$CODEX_HOME"
    if [ -z "$codex_home" ]; then
      codex_home="$HOME/.codex"
    fi

    session_dir="$codex_home/sessions"
    if [ ! -d "$session_dir" ]; then
      echo "CODEX --"
      exit 0
    fi

    session_file=$(
      ${pkgs.findutils}/bin/find "$session_dir" -type f -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null \
        | ${pkgs.coreutils}/bin/sort -nr \
        | ${pkgs.coreutils}/bin/cut -d' ' -f2- \
        | ${pkgs.gnused}/bin/sed -n '1p'
    )

    if [ -z "$session_file" ]; then
      echo "CODEX --"
      exit 0
    fi

    snapshot=$(
      ${pkgs.coreutils}/bin/tail -n 500 "$session_file" \
        | ${pkgs.jq}/bin/jq -r '
          select(.type == "event_msg" and .payload.type == "token_count")
          | [.payload.info.last_token_usage.total_tokens,
             .payload.info.model_context_window,
             .payload.rate_limits.primary.used_percent,
             .payload.rate_limits.secondary.used_percent]
          | @tsv' \
        | ${pkgs.coreutils}/bin/tail -n1
    )

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

    printf 'CODEX CTX %s%% (%s) | PLAN 5h %.0f%% / 7d %.0f%%\n' \
      "$context_pct" "$tokens_display" "''${five_hour:-0}" "''${seven_day:-0}"
  '';
in

{
  home.packages = [
    codexbar
    pkgs.networkmanagerapplet
  ];

  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };

    script = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator & polybar top &";

    config = {
      "settings" = {
        "screenchange-reload" = true;
      };

      "bar/top" = {
        width = "100%";
        height = "20px";
        radius = 0;
        fixed-center = true;
        background = "#E6222222";
        foreground = "#ffffff";
        font-0 = "JetBrainsMono Nerd Font:size=10;2";
        line-size = 2;
        padding-left = 0;
        padding-right = 2;
        module-margin = 1;
        tray-position = "right";
        tray-padding = 2;
        modules-left = "i3";
        modules-right = "cpu memory backlight pulseaudio wlan battery codexbar date";
      };

      "module/i3" = {
        type = "internal/i3";
        format = "<label-state>";
        index-sort = true;
        label-active = "%index%";
        label-active-background = "#444444";
        label-active-padding = 2;
        label-occupied = "%index%";
        label-occupied-padding = 2;
        label-empty = "%index%";
        label-empty-padding = 2;
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format = "󰍛 <label>";
        label = "%percentage%%";
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format = "󰘚 <label>";
        label = "%percentage_used%%";
      };

      "module/backlight" = {
        type = "internal/backlight";
        card = "intel_backlight";
        format = "󰃠 <label>";
        label = "%percentage%%";
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "󰕾 <label-volume>";
        label-volume = "%percentage%%";
        label-muted = "󰖁 muted";
      };

      "module/wlan" = {
        type = "internal/network";
        interface-type = "wireless";
        interval = 5;
        format-connected = "󰖩 <label-connected>";
        format-disconnected = "󰖪 disconnected";
        label-connected = "%essid%";
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "AC";
        poll-interval = 5;
        format-charging = "<ramp-capacity> <label-charging>";
        format-discharging = "<ramp-capacity> <label-discharging>";
        format-full = "󰁹 <label-full>";
        label-charging = "%percentage%%";
        label-discharging = "%percentage%%";
        label-full = "100%";
        ramp-capacity-0 = "󰂎";
        ramp-capacity-1 = "󰁺";
        ramp-capacity-2 = "󰁻";
        ramp-capacity-3 = "󰁼";
        ramp-capacity-4 = "󰁽";
        ramp-capacity-5 = "󰁾";
        ramp-capacity-6 = "󰁿";
        ramp-capacity-7 = "󰂀";
        ramp-capacity-8 = "󰂁";
        ramp-capacity-9 = "󰂂";
        ramp-capacity-10 = "󰁹";
      };

      "module/codexbar" = {
        type = "custom/script";
        exec = "${codexbar}/bin/codexbar";
        interval = 10;
        format = "<label>";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%Y-%m-%d";
        time = "%H:%M:%S";
        label = "%date% %time%";
      };
    };
  };

  systemd.user.services.polybar.Install.WantedBy = [ "i3-session.target" ];
}
