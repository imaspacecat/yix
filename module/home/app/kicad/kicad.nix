{ pkgs, ... }:

let
  kbplacer = pkgs.lib.makeOverridable (
    {
      addonPath ? "addon.zip",
      python3 ? pkgs.python3,
    }:
    pkgs.linkFarm "kicadaddon-kbplacer-0.19" [
      {
        name = addonPath;
        path = pkgs.fetchurl {
          url = "https://github.com/adamws/kicad-kbplacer/releases/download/v0.19/kbplacer-0.19.zip";
          sha256 = "88d707177240328ad69c9d5d73dcd521d9bb8176aca7cfb57ed0d0c0eea54dab";
        };
      }
    ]
  ) { };

  marbastlib = pkgs.fetchzip {
    name = "marbastlib-2026.03.22";
    url = "https://github.com/ebastler/marbastlib/releases/download/2026.03.22/KiCAD-PCM-2026.03.22.zip";
    hash = "sha256-PwuySZdNx2NzUDJotE7n9rEkulaUl3sIidyyQSjL4Pg=";
    stripRoot = false;
  };

in
{
  home.packages = [
    (pkgs.kicad.override { addons = [ kbplacer ]; })
  ];

  xdg.dataFile = {
    "kicad/10.0/3rdparty/3dmodels/com_github_ebastler_marbastlib".source = "${marbastlib}/3dmodels";
  };

  xdg.configFile = {
    "kicad/10.0/fp-lib-table".source = pkgs.replaceVars ./fp-lib-table { inherit marbastlib; };
    "kicad/10.0/sym-lib-table".source = pkgs.replaceVars ./sym-lib-table { inherit marbastlib; };
  };
}
