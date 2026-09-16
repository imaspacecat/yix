{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
  ];

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions =
        (with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          ms-python.vscode-pylance
          ms-python.python
          ms-python.debugpy
          ms-toolsai.jupyter
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          ms-vscode.cpptools-extension-pack
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ritwickdey.liveserver
          mshr-h.veriloghdl
          tamasfe.even-better-toml
        ])
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "tabout";
            publisher = "albert";
            version = "0.2.2";
            sha256 = "sha256-s306AHMkUFPaG7ISIr0RscK/k6OVtniIG1CQprBx+cY=";
          }
          {
            name = "rainbow-csv";
            publisher = "mechatroner";
            version = "3.24.1";
            sha256 = "sha256-xZpK6pJNXnxudauzJihEi9VASRXi89+hn7vfF33qRgY=";
          }
          {
            name = "pioasm";
            publisher = "chris-hock";
            version = "1.0.0";
            sha256 = "sha256-OPDqDBefXQeRPqk24LoJ+wXsCvGO6bgJThRaeOZi5yY=";
          }
        ];

      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "window.zoomLevel" = 1;
        "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
        "editor.formatOnSave" = true;
        "remote.SSH.path" = "${pkgs.openssh}/bin/ssh";
        "remote.SSH.defaultExtensions" = [
          "jnoortheen.nix-ide"
          "ms-python.vscode-pylance"
          "ms-python.python"
          "ms-python.debugpy"
          "ms-toolsai.jupyter"
          "ms-vscode.cpptools"
          "ms-vscode.cmake-tools"
          "mshr-h.veriloghdl"
          "tamasfe.even-better-toml"
          "chris-hock.pioasm"
        ];
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };
    };
  };
}
