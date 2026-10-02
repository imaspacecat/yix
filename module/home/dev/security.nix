{ pkgs, ... }:

{
  home.packages = with pkgs; [
    amass
    ffuf
    (lib.hiPrio httpx)
    katana
    mitmproxy
    subfinder
  ];
}
