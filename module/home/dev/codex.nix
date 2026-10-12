{ pkgs, inputs, ... }:

let
  upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

  kicad-happy = pkgs.fetchFromGitHub {
    owner = "aklofas";
    repo = "kicad-happy";
    rev = "06840467ad0f5d76af45f64449b1f5ecb10f052f";
    hash = "sha256-nnlQ3wNipgi5X+fimRlgzKXyTMOypR7Sw3JzlTpt0hg=";
  };

  manifest = builtins.toJSON {
    layoutVersion = 1;
    version = upstream.version;
    target = pkgs.stdenv.hostPlatform.rust.rustcTarget;
    variant = "codex";
    entrypoint = "bin/codex";
    resourcesDir = "codex-resources";
    pathDir = "codex-path";
  };

  codex = pkgs.runCommand "codex-${upstream.version}-fixed" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = upstream.meta;
    inherit upstream manifest;
    ripgrep = pkgs.ripgrep;
    bubblewrap = pkgs.bubblewrap;
  } (builtins.readFile ../../../scripts/build-codex);
in
{
  home.packages = [
    pkgs.ngspice
    pkgs.poppler-utils
  ];

  programs.codex = {
    enable = true;
    package = codex;
    skills = "${kicad-happy}/skills";
  };
}
