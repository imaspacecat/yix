{ ... }:

{
  programs.alacritty = {
    enable = true;

    settings.general = {
      live_config_reload = false;
      ipc_socket = false;
    };

    settings = {
      font = {
        normal.family = "JetBrainsMono Nerd Font Mono";
        bold.family = "JetBrainsMono Nerd Font Mono";
        size = 8.0;
      };

      colors = {
        primary = {
          background = "#101014";
          foreground = "#d8d8de";
        };
        cursor = {
          cursor = "#d8d8de";
          text = "#101014";
        };
        selection = {
          background = "#303039";
          text = "#d8d8de";
        };
        normal = {
          black = "#101014";
          red = "#d16969";
          green = "#98c379";
          yellow = "#d7ba7d";
          blue = "#61afef";
          magenta = "#c678dd";
          cyan = "#56b6c2";
          white = "#dcdfe4";
        };
        bright = {
          black = "#303039";
          red = "#e06c75";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#d8d8de";
        };
      };
    };
  };
}
