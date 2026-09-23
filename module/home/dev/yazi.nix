{ config, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [
    ps.dbus-python
    ps.pygobject3
  ]);

  yaziFileManager = pkgs.writeTextFile {
    name = "yazi-file-manager";
    destination = "/bin/yazi-file-manager";
    executable = true;
    text = ''
      #!${python}/bin/python3
      import subprocess
      from urllib.parse import unquote, urlparse

      import dbus
      import dbus.service
      from dbus.mainloop.glib import DBusGMainLoop
      from gi.repository import GLib


      def local_paths(uris):
          paths = []
          for uri in uris:
              parsed = urlparse(uri)
              if parsed.scheme == "file" and parsed.netloc in ("", "localhost"):
                  paths.append(unquote(parsed.path))
          return paths


      class FileManager(dbus.service.Object):
          def open(self, uris):
              paths = local_paths(uris)
              if paths:
                  subprocess.Popen(
                      ["${pkgs.rxvt-unicode}/bin/urxvt", "-name", "yazi", "-e", "${config.home.profileDirectory}/bin/yazi", *paths],
                      start_new_session=True,
                  )

          @dbus.service.method("org.freedesktop.FileManager1", in_signature="ass")
          def ShowItems(self, uris, startup_id):
              self.open(uris)

          @dbus.service.method("org.freedesktop.FileManager1", in_signature="ass")
          def ShowFolders(self, uris, startup_id):
              self.open(uris)

          @dbus.service.method("org.freedesktop.FileManager1", in_signature="ass")
          def ShowItemProperties(self, uris, startup_id):
              self.open(uris)


      DBusGMainLoop(set_as_default=True)
      bus = dbus.SessionBus()
      name = dbus.service.BusName("org.freedesktop.FileManager1", bus=bus)
      manager = FileManager(bus, "/org/freedesktop/FileManager1")
      GLib.MainLoop().run()
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
      _7zz
      chafa
      exiftool
      ffmpeg
      ffmpegthumbnailer
      imagemagick
      poppler
      resvg
      ueberzugpp
      zoxide
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
