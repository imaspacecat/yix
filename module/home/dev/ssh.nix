{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
      "github.com" = {
        Hostname = "github.com";
        IdentityFile = "~/.ssh/git_id_ed25519";
        IdentitiesOnly = "yes";
      };
      "ews" = {
        Hostname = "linux.ews.illinois.edu";
        User = "dubiner2";
        IdentityFile = "~/.ssh/ews_id_ed25519";
        IdentitiesOnly = "yes";
        ForwardAgent = "yes";
      };
    };
  };
}
