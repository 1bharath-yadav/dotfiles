# Effective Nix & Home Manager Guide

Welcome to your new pure, declarative infrastructure! Since you transitioned away from standard GNU Stow mappings and Pacman system-wide installs for your tools, here is the expert playbook for managing your system effectively.

---

## 1. Declaratively Managing Packages

You should almost never use `sudo pacman -S <tool>` or `apt install <tool>` for CLI utilities, language servers, network tools, or apps (unless they require deep OS-level drivers like `nvidia`, `docker` daemon, or complex Wayland portals like `xdg-desktop-portal`). 

Instead, put them in your **Home Manager `packages.nix`**:

- **Cross-platform CLI packages (Arch, WSL, Phone):** Add them to `~/.dotfiles/nix/modules/core/packages.nix`
- **Linux-specific packages (GUI apps like Chrome, OBS, Zed):** Add them to `~/.dotfiles/nix/modules/linux/packages.nix`

*How to apply your changes:*
```bash
apply-dotfiles
# or manually:
git add .
nix run home-manager/master -- switch --flake ~/.dotfiles#archer-arch
```
*(Always remember to `git add` new files or modifications before running switch, otherwise Nix will ignore them or throw a dirty tree warning).*

---

## 2. Using `nix shell` (The Superpower)

Never install a package just to use it once. If you need a tool (like `python3`, `nmap`, or `ffmpeg`) for a quick task, spawn an ephemeral environment. When you exit, it leaves no trace on your OS.

```bash
# Need to use 'ffmpeg' to convert a video real quick?
nix shell nixpkgs#ffmpeg

# Need python with requests and beautifulsoup?
nix shell nixpkgs#python311 nixpkgs#python311Packages.requests nixpkgs#python311Packages.beautifulsoup4

# Or run a command directly without entering a shell environment:
nix run nixpkgs#cowsay "Hello world!"
```

---

## 3. Searching for Nix Packages

Don't guess the package name. You can search the vast Nixpkgs repository natively or via the web.

**In the terminal:**
```bash
nix search nixpkgs <search_term>
```
**On the web:**
Visit [search.nixos.org](https://search.nixos.org/packages) — this is usually faster and shows you exact configuration options and versions.

---

## 4. Updates & Synching Upstream (`flake.lock`)

Your packages are pinned perfectly to specific commits in the `flake.lock` file. This means if you switch environments today or 3 years from now, you get the EXACT same versions of tools. 

To update your tools to the latest versions across the board:
```bash
cd ~/.dotfiles
nix flake update
apply-dotfiles  # or your update.sh command
```
This updates the lockfile and fetches the newest binary releases of all your tools.

---

## 5. Rolling Back (Time Travel)

If you ran an update or broke a configuration and your terminal won't launch, or an app is crashing, you can instantly revert to the previous working Home Manager generation.

```bash
# List all generations
home-manager generations --flake ~/.dotfiles#archer-arch

# Rollback to the immediate last working state
home-manager expire-generations "-1 days" # to delete recent broken ones
# Or switch to a specific ID from the generations list:
/nix/store/...-home-manager-generation/activate
```

---

## 6. Garbage Collection (Reclaiming Space)

Nix stores every version of every package you've ever installed in `/nix/store`. Over time, this consumes gigabytes of space. Unlike traditional package managers, you have to tell it to clean up orphaned packages explicitly.

```bash
# Clean up dependencies that are no longer referenced by a flake or generation
nix-collect-garbage -d

# To do it safely optimizing hardlinks (saves extra space):
nix-store --optimize
```
*Tip: Put `nix-collect-garbage -d` in an alias and run it every few weeks to keep your disk lean.*

---

## 7. Working with Configurations (e.g. Neovim / Yazi)

Configurations are housed entirely in `~/.dotfiles/nix/modules/programs/<tool>/config`.
Nix symlinks the entire folder to `$HOME/.config/<tool>`.

If you are just editing Lua files for Neovim (like updating a keybind), **you don't need to run Home Manager switch!** Because the files are actively symlinked back to `~/.dotfiles/nix/modules/programs/nvim/config/`, changes in those files inside the dotfiles repo are instantly reflected in Neovim when you save. 

You ONLY need to run `nix run home-manager/master -- switch` when you:
1. Add/Remove a package
2. Modify a `.nix` file
3. Change paths or structure
