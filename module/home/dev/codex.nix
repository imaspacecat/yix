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
      }
      ''
        bundle="$out/libexec/codex"
        mkdir -p "$bundle/bin" "$bundle/codex-path" \
          "$bundle/codex-resources" "$out/bin"

        cp -a ${upstream}/libexec/codex/bin/. "$bundle/bin/"
        install -m755 ${pkgs.ripgrep}/bin/rg "$bundle/codex-path/rg"
        install -m755 ${pkgs.bubblewrap}/bin/bwrap \
          "$bundle/codex-resources/bwrap"

        printf '%s\n' ${pkgs.lib.escapeShellArg manifest} \
          > "$bundle/codex-package.json"

        makeWrapper "$bundle/bin/codex" "$out/bin/codex" \
          --prefix PATH : ${pkgs.bubblewrap}/bin \
          --add-flags '-c approval_policy="never" -c sandbox_mode="danger-full-access"'

        ln -s ../libexec/codex/bin/codex-code-mode-host \
          "$out/bin/codex-code-mode-host"
        ln -s ../libexec/codex/bin/logs_client "$out/bin/logs_client"

        cp -a ${upstream}/share "$out/share"
      '';
in
{
  programs.codex = {
    enable = true;
    package = codex;
  };
}
