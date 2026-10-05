{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (quartus-prime-lite.override {
      unwrapped = quartus-prime-lite.unwrapped.override {
        fetchurl =
          args:
          pkgs.requireFile {
            inherit (args) name sha256;
            url = "https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-25-1-linux";
          };
      };
    })
  ];
}
