# Dotfiles Setup with GNU Stow

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to manage and symlink configuration files for various applications. Stow makes it easy to keep your dotfiles organized and portable.

## Folder Structure
Each directory in this repo (e.g., `nvim/`, `zsh/`, `kitty/`, etc.) contains configuration files for a specific application. Stow will symlink these files to your home directory.

## Quick Setup
1. **Clone the repository:**
   ```zsh
   git clone https://github.com/1bharath-yadav/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Symlink configs using Stow:**
   For example, to set up Neovim configs:
   ```zsh
   stow nvim
   ```
   To set up all configs:
   ```zsh
   stow */  
   ```
   (You can also run `stow <folder>` for each config you want.)mos

## Notes
- If you need to remove symlinks, use:
    ```zsh
    stow -D <folder>
    ```
- If you encounter conflicts, manually remove or backup existing dotfiles before running Stow.

## Basic usage

#### Stow a package (create symlinks)
```zsh
stow --target=$HOME package-name
```

#### Stow with verbose output
```zsh
stow --verbose --target=$HOME package-name
```

#### Stow multiple packages
```zsh
stow --verbose --target=$HOME package1 package2 package3
```

#### Unstow a package (remove symlinks)
```zsh
stow --delete --verbose --target=$HOME package-name
```

#### Dry run (see what would happen without making changes)
```zsh
stow --simulate --verbose --target=$HOME package-name
```

#### Stow all directories except specified ones
```zsh
stow --verbose --target=$HOME --ignore='readme.md|.git' */
```

#### Restow (useful after making changes to package)
```zsh
stow --restow --verbose --target=$HOME package-name
```

#### Use adopter mode for conflicting files
```zsh
stow --adopt --verbose --target=$HOME package-name
```

