{ config, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [
    ps.dbus-python
    ps.pygobject3
  ]);

  yaziFileManager = pkgs.writeShellApplication {
    name = "yazi-file-manager";
    runtimeInputs = [ python ];
    text = ''
      exec python3 ${../../../scripts/yazi-file-manager} ${pkgs.rxvt-unicode}/bin/urxvt ${config.home.profileDirectory}/bin/yazi
    '';
  };

  yaziFileManagerService = pkgs.writeTextFile {
    name = "yazi-file-manager-service";
    destination = "/share/dbus-1/services/org.freedesktop.FileManager1.service";
    text = ''
      [D-BUS Service]
      Name=org.freedesktop.FileManager1
      Exec=${yaziFileManager}/bin/yazi-file-manager
    '';
  };
in
{
  home.packages = [ yaziFileManagerService ];

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;

    extraPackages = with pkgs; [
      exiftool
      ffmpegthumbnailer
      ueberzugpp
    ];

    settings = {
      opener.edit = [
        {
          run = ''vim "$@"'';
          block = true;
          for = "unix";
        }
      ];
    };
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    genericName = "File Manager";
    exec = "urxvt -name yazi -e yazi %u";
    mimeType = [ "inode/directory" ];
    terminal = false;
    icon = "yazi";
    categories = [
      "System"
      "FileTools"
      "FileManager"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "yazi.desktop" ];
    };
  };
}
