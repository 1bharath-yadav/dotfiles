{ ... }:

{
  programs.git = {
    enable = true;
    signing.format = null;

    settings = {
      user = {
        name  = "1bharath-yadav";
        email = "byadhav36@gmail.com";
      };
      core = {
        pager       = "delta";
        editor      = "nvim";
        autocrlf    = "input";
        whitespace  = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        excludesfile = "~/.gitignore_global";
      };
      init.defaultBranch   = "main";
      credential.helper    = "store";
      interactive.diffFilter = "delta --color-only";
      merge = { conflictStyle = "zdiff3"; tool = "nvimdiff"; };
      diff  = { algorithm = "histogram"; colorMoved = "default"; renames = "copies"; };
      rebase = { autosquash = true; autostash = true; };
      pull.rebase           = true;
      push  = { default = "current"; autoSetupRemote = true; };
      fetch = { prune = true; pruneTags = true; };
      status.showUntrackedFiles = "all";
      branch.sort = "-committerdate";
      tag.sort    = "version:refname";

      "filter \"lfs\"" = {
        clean   = "git-lfs clean -- %f";
        smudge  = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      delta = {
        navigate    = true;
        line-numbers = true;
        hyperlinks  = true;
        syntax-theme = "ansi";
        minus-style      = ''syntax "#3a2020"'';
        minus-emph-style = ''syntax "#6b2020"'';
        plus-style       = ''syntax "#1e3a1e"'';
        plus-emph-style  = ''syntax "#1e5c1e"'';
        line-numbers-minus-style = "#e06c75";
        line-numbers-plus-style  = "#98c379";
        line-numbers-zero-style  = "#393e48";
        hunk-header-style            = ''syntax "#2c313a"'';
        hunk-header-decoration-style = ''"#393e48 box"'';
      };

      alias = {
      # status & info
      st   = "status --short --branch";
      s    = "status";
      show = "show --stat";
      # log
      lg   = ''log --graph --topo-order --date=short --abbrev-commit --decorate --all --boundary --pretty=format:"%Cgreen%ad %Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue[%cn]%Creset"'';
      ll   = "log --oneline --graph --full-history --all --color --decorate";
      lm   = ''log --since="last month" --oneline'';
      lw   = "log --since=1-week-ago --oneline";
      ld   = "log --since=1-day-ago --oneline";
      lmine = "!git log --author=$(git config user.email) --oneline";
      who  = "shortlog --summary --numbered --no-merges";
      # staging
      a  = "add";
      aa = "add --all";
      ap = "add --patch";
      # committing
      c    = "commit";
      cm   = "commit --message";
      ca   = "commit --amend";
      cane = "commit --amend --no-edit";
      fixup = "commit --fixup";
      wip  = "!git add -A && git commit -m 'wip'";
      # branching
      b   = "branch";
      bd  = "branch -d";
      bD  = "branch -D";
      bl  = "branch -l";
      br  = "branch -r";
      cb  = "checkout -b";
      co  = "checkout";
      sw  = "switch";
      swc = "switch -c";
      # diff
      d     = "diff";
      dc    = "diff --cached";
      dstat = "diff --stat --ignore-space-change -r";
      dw    = "diff --word-diff";
      # remote
      f   = "fetch --prune";
      pl  = "pull";
      ps  = "push";
      pso = "push origin";
      psu = "push --set-upstream origin HEAD";
      rv  = "remote -v";
      # rebase / reset
      rb   = "rebase";
      rbi  = "rebase -i";
      rba  = "rebase --abort";
      rbc  = "rebase --continue";
      rh   = "reset --hard";
      rs   = "reset --soft";
      undo = "reset --soft HEAD~1";
      # stash
      ss = "stash save";
      sl = "stash list";
      sp = "stash pop";
      sd = "stash drop";
      # misc
      root  = "rev-parse --show-toplevel";
      head  = "rev-parse --abbrev-ref HEAD";
      tags  = "tag -l";
      clout = "!git clean -df && git checkout -- .";
      };
    };
  };
}
