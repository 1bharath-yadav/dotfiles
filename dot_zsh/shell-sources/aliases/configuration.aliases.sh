#!/usr/bin/env bash
# configuration.aliases.sh — quick-edit shortcuts for common config files

# Use EDITOR from env (set to nvim in env.zsh)
: "${EDITOR:=nvim}"

alias edit_bashrc='$EDITOR $HOME/.bashrc'
alias edit_zshrc='$EDITOR $HOME/.config/zsh/.zshrc'
alias edit_zsh_profile='$EDITOR $HOME/.zsh_profile'
alias edit_ssh_config='$EDITOR $HOME/.ssh/config'
alias edit_git_config='$EDITOR $HOME/.gitconfig'
alias edit_git_ignore='$EDITOR $HOME/.gitignore'
alias edit_hosts='$EDITOR /etc/hosts'
alias edit_nginx_config='$EDITOR /etc/nginx/nginx.conf'
alias edit_docker_compose='$EDITOR docker-compose.yml'
alias edit_dotfiles='$EDITOR $HOME/dotfiles'
alias edit_hypr='$EDITOR $HOME/.config/hypr/hyprland.conf'
alias edit_quickshell='$EDITOR $HOME/.config/quickshell'
alias edit_iiconfig='$EDITOR $HOME/.config/illogical-impulse/config.json'
