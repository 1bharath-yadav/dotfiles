{ pkgs, ... }:

# mise — runtime/version manager
#
# Version pin policy:
#   - Pin stable versions that you actively use across projects.
#   - Bump intentionally when you need newer features; not automatically.
#   - Keep in sync with what sync-external-tools installs via `mise install`.
#
# Why here instead of external.txt:
#   - This file is Home-Manager-managed and symlinked to Nix store.
#   - mise reads [tools] from config; we don't want it trying to write here.
#   - sync-external-tools just runs `mise install` to materialize the runtimes.

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".text = ''
    [tools]
    python = "3.12"
    node = "lts"          # required by letta-code and gemini-cli
    rust = "latest"
    uv = "latest"
    pnpm = "latest"
    "github:cli/cli" = "2"

    # # Node global tools (pnpm: prefix uses mise-managed pnpm)
    # "pnpm:@letta-ai/letta-code" = "latest"
    # "pnpm:@google/gemini-cli" = "latest"
    #
    [settings]
    legacy_version_file = true
    idiomatic_version_file_enable_tools = ["python", "node", "rust", "uv", "pnpm"]
    install_before = "7d"
    jobs = 8
    status.missing_tools = "if_other_versions_installed"

    [settings.cargo]
    binstall = true

    [settings.github]
    gh_cli_tokens = true
  '';
}
