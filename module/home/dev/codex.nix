{ pkgs, inputs, ... }:

let
  upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

  manifest = builtins.toJSON {
    layoutVersion = 1;
    version = upstream.version;
    target = pkgs.stdenv.hostPlatform.rust.rustcTarget;
    variant = "codex";
    entrypoint = "bin/codex";
    resourcesDir = "codex-resources";
    pathDir = "codex-path";
  };

  codex =
    pkgs.runCommand "codex-${upstream.version}-fixed"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = upstream.meta;
        inherit upstream manifest;
        ripgrep = pkgs.ripgrep;
        bubblewrap = pkgs.bubblewrap;
      }
      (builtins.readFile ../../../scripts/build-codex);
in
{
  programs.codex = {
    enable = true;
    package = codex;
  };
}
