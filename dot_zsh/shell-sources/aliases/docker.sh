#!/usr/bin/env bash
# docker.sh — docker / compose / swarm aliases

command -v docker >/dev/null 2>&1 || return 0

# ── Core ──────────────────────────────────────────────────────────────────────
alias dk='docker'
alias dkv='docker version'
alias dkinfo='docker info'
alias dkl='docker login'
alias dklo='docker logout'

# ── Containers ────────────────────────────────────────────────────────────────
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dkr='docker run'
alias dkri='docker run -it'
alias dkrd='docker run -d'
alias dks='docker start'
alias dkst='docker stop'
alias dkrs='docker restart'
alias dkp='docker pause'
alias dkup='docker unpause'
alias dkrm='docker rm'
alias dkrma='docker rm $(docker ps -aq)'
alias dkrmf='docker rm -f'
alias dkin='docker inspect'
alias dklogs='docker logs'
alias dklf='docker logs -f'
alias dktop='docker top'
alias dkstat='docker stats'
alias dkex='docker exec'
alias dkeit='docker exec -it'
alias dkcp='docker cp'
alias dkk='docker kill'
alias dkatt='docker attach'
alias dkcom='docker commit'
alias dkw='docker wait'

# ── Images ────────────────────────────────────────────────────────────────────
alias dkim='docker images'
alias dkia='docker images -a'
alias dkb='docker build'
alias dkbt='docker build -t'
alias dkpl='docker pull'
alias dkpu='docker push'
alias dkrmi='docker rmi'
alias dkh='docker history'
alias dksv='docker save'
alias dkld='docker load'
alias dktag='docker tag'
alias dkexp='docker export'
alias dkimp='docker import'
alias dkprune='docker system prune'
alias dkprunea='docker system prune -a'
alias dkrmi_dangling='docker rmi $(docker images -f "dangling=true" -q)'

# ── Volumes ───────────────────────────────────────────────────────────────────
alias dkvls='docker volume ls'
alias dkvc='docker volume create'
alias dkvi='docker volume inspect'
alias dkvrm='docker volume rm'
alias dkvp='docker volume prune'

# ── Networks ──────────────────────────────────────────────────────────────────
alias dknls='docker network ls'
alias dknc='docker network create'
alias dkni='docker network inspect'
alias dknrm='docker network rm'
alias dknp='docker network prune'
alias dkncon='docker network connect'
alias dkndis='docker network disconnect'

# ── System ────────────────────────────────────────────────────────────────────
alias dksdf='docker system df'
alias dksev='docker system events'
alias dksi='docker system info'
alias dksp='docker system prune'
alias dkspa='docker system prune -a'
alias dkcon='docker context'

# ── Docker Compose ────────────────────────────────────────────────────────────
if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then
  _dc() { command -v docker-compose >/dev/null 2>&1 && docker-compose "$@" || docker compose "$@"; }
  alias dc='_dc'
  alias dcu='_dc up'
  alias dcud='_dc up -d'
  alias dcd='_dc down'
  alias dcdv='_dc down -v'
  alias dcr='_dc restart'
  alias dcs='_dc stop'
  alias dcsta='_dc start'
  alias dcps='_dc ps'
  alias dcl='_dc logs'
  alias dclf='_dc logs -f'
  alias dcex='_dc exec'
  alias dcb='_dc build'
  alias dcpull='_dc pull'
  alias dcpush='_dc push'
  alias dcrm='_dc rm'
  alias dcrun='_dc run'
  alias dci='_dc images'
  alias dck='_dc kill'
  alias dccfg='_dc config'
  alias dcev='_dc events'
  alias dctop='_dc top'
  alias dcv='_dc version'
fi
