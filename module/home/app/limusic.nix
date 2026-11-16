{ pkgs, ... }:

let
  pname = "limusic";
  version = "1.3.0";
  src = pkgs.fetchurl {
    url = "https://github.com/SimoHypers/limusic/releases/download/v${version}/limusic_${version}_amd64.AppImage";
    hash = "sha256-skhW7OeTMN06Y/WvI5Tm+Dja50rtxh42d0Q96Qwrc4c=";
  };
  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
{
  home.packages = [
    (pkgs.appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -Dm644 ${appimageContents}/limusic.desktop $out/share/applications/limusic.desktop
        substituteInPlace $out/share/applications/limusic.desktop \
          --replace-fail 'Exec=limusic-app' "Exec=$out/bin/limusic"
        cp -r ${appimageContents}/usr/share/icons $out/share/
      '';
      meta = {
        description = "Native desktop YouTube Music client";
        homepage = "https://github.com/SimoHypers/limusic";
        license = pkgs.lib.licenses.gpl3Only;
        mainProgram = pname;
        platforms = [ "x86_64-linux" ];
      };
    })
  ];
}
