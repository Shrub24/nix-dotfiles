_: {
  flake.modules.homeManager.tmux = {
    programs.tmux = {
      enable = true;

      clock24 = true;
      historyLimit = 50000;
      mouse = true;
      escapeTime = 0;

      extraConfig = ''
        set -g default-terminal "tmux-256color"
        set-option -ga terminal-overrides ",*256col*:Tc"
        set-option -ga terminal-overrides ',*:Smplx=\E[%p1%d q'

        set -g base-index 1
        setw -g pane-base-index 1

        set -g focus-events on
        set -g aggressive-resize on
        set -g window-size latest
        set -g renumber-windows on
        set -g destroy-unattached off

        set -g set-titles on
        set -g set-titles-string "#S — tmux"

        setw -g monitor-activity on
        set -g visual-activity on

        set -g display-time 3000
        set -g display-panes-time 3000

        set -g status-interval 5
        set -g status-left "#[fg=green]#S "
        set -g status-right "#[fg=yellow]%Y-%m-%d %H:%M "

        bind R source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

        bind r copy-mode \; command-prompt -p "search:" "send-keys -X search-forward-incremental '%%%'"

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5
      '';
    };
  }

  ;
}
