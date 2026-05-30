{
  programs.tmux = {
    enable = true;

    # Sensible base settings for persistent remote sessions
    clock24 = true;
    historyLimit = 50000;
    mouse = true;
    escapeTime = 0;

    extraConfig = ''
      # Set default terminal to support 256 colour and true colour
      set -g default-terminal "tmux-256color"
      set-option -ga terminal-overrides ",*256col*:Tc"
      set-option -ga terminal-overrides ',*:Smplx=\E[%p1%d q'

      # Start window numbering at 1 (easier to reach on phone keyboard)
      set -g base-index 1
      setw -g pane-base-index 1

      # Focus events for wezterm and modern terminals
      set -g focus-events on

      # Aggressive resize for mosh — adapt quickly to changing terminal sizes
      set -g aggressive-resize on

      # Use most recently attached client size (avoids shrinking to smallest)
      set -g window-size latest

      # Re-number windows when one is closed
      set -g renumber-windows on

      # Never destroy a session when all clients detach (essential for mosh)
      set -g destroy-unattached off

      # Keep sessions alive after the last client detaches
      set -g set-titles on
      set -g set-titles-string "#S — tmux"

      # Activity monitoring for long-running processes
      setw -g monitor-activity on
      set -g visual-activity on

      # Raise display time on phone (easier to read mode indicators)
      set -g display-time 3000
      set -g display-panes-time 3000

      # Status bar: concise, session-focused
      set -g status-interval 5
      set -g status-left "#[fg=green]#S "
      set -g status-right "#[fg=yellow]%Y-%m-%d %H:%M "

      # Key bindings
      bind R source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Quick scrollback search (C-b r) — essential on phone without terminal scroll
      bind r copy-mode \; command-prompt -p "search:" "send-keys -X search-forward-incremental '%%%'"

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # vim-style resize
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
    '';
  };
}
