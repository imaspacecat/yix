{ pkgs, ... }:

let
  python = pkgs.python312.withPackages (
    pythonPackages: with pythonPackages; [
      ipykernel
      jupyter
    ]
  );
in

{
  home.packages = with pkgs; [
    uv
    python
    ruff
    libnotify
  ];
}
