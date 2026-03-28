# core/packages.nix — universal CLI tools available on ALL hosts (arch, wsl, android)
#
# RULE: if it's Arch/GUI-specific, it goes in profiles/arch-desktop.nix
#       if it's a rarely-used or optional tool, it goes in profiles/extras.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── File & search ───────────────────────────────────────────────────────────
    bat           # cat with syntax highlighting
    eza           # modern ls
    fd            # fast find
    file          # file type detection
    fzf           # fuzzy finder
    ripgrep       # fast grep
    trash-cli     # safe rm
    tree          # directory tree
    unzip
    zip
    zoxide        # smart cd

    # ── Terminal utilities ───────────────────────────────────────────────────────
    asciinema     # terminal recording
    chafa         # image-to-ascii in terminal
    fastfetch     # system info
    glow          # markdown in terminal
    parallel      # run commands in parallel
    tealdeer      # tldr pages

    # ── Data & text ─────────────────────────────────────────────────────────────
    cmark         # CommonMark markdown
    fx            # interactive JSON viewer
    jq            # JSON processor
    jqp           # jq TUI playground
    pandoc        # document converter

    # ── Networking ──────────────────────────────────────────────────────────────
    aria2         # download manager
    httpie        # user-friendly HTTP client
    nmap          # network scanner
    rclone        # cloud storage sync
    xh            # fast HTTP client (httpie-compatible)

    # ── Dev & Git ───────────────────────────────────────────────────────────────
    gh            # GitHub CLI
    gitui         # terminal Git UI
    shellcheck    # shell script linter
    direnv        # per-directory env vars

    # ── AI / modern CLI ─────────────────────────────────────────────────────────
    opencode      # AI coding CLI

    # ── Containers ──────────────────────────────────────────────────────────────
    containerd
    distrobox

    # ── Media (headless-safe) ───────────────────────────────────────────────────
    ffmpegthumbnailer
    mediainfo
    yt-dlp

    # ── Misc ────────────────────────────────────────────────────────────────────
    eget          # install GitHub release binaries
    fdupes        # find duplicate files
    pngquant      # PNG compression
    resvg         # SVG renderer
    starship      # prompt (also declared via programs.starship)
  ];
}
