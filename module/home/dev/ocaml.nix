{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ocaml
    dune
    opam
    rlwrap
    ocamlPackages.findlib
    ocamlPackages.utop
  ];
}
