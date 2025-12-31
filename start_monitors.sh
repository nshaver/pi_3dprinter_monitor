#!/bin/bash

# 1. Kill any existing sessions
tmux kill-session -t printers 2>/dev/null

# 2. Start a new session in the background
tmux new-session -d -s printers

# 3. Configure the Status Bar (Pi Health)
# Set refresh interval
tmux set-option -g status-interval 2

# --- Clean up the middle (Remove |0:bash*) ---
tmux set-option -g window-status-format ""
tmux set-option -g window-status-current-format ""

# --- Configure the Status Bar Style ---
tmux set-option -g status-style bg=default,fg=white
tmux set-option -g status-left-length 30
tmux set-option -g status-right-length 150

# --- The New Status Bar Layout ---
IP_ADDR=$(hostname -I | awk '{print $1}')
# Left: IP Address
# Right: Memory % | CPU % | Temp | Power | Temp Health | Time
tmux set-option -g status-left "#[fg=yellow,bold]IP: $IP_ADDR #[fg=white]| "
tmux set-option -g status-right "\
#[fg=blue,bold]MEM: #(free | grep Mem | awk '{printf \"%%d%%%%\", \$3/\$2 * 100.0}') #[fg=white]| \
#[fg=magenta,bold]CPU: #(awk '{printf \"%%d%%%%\", \$1*25}' /proc/loadavg) #[fg=white]| \
#[fg=cyan,bold]#(vcgencmd measure_temp | cut -d= -f2) #[fg=white]| \
#(STATUS=\$(vcgencmd get_throttled | cut -d= -f2); \
  if [ \$((STATUS & 0x5)) -ne 0 ]; then \
    echo '#[fg=red,bold,blink]PWR:LOW'; \
  elif [ \$((STATUS & 0x50000)) -ne 0 ]; then \
    echo '#[fg=yellow]PWR:OK'; \
  else \
    echo '#[fg=green]PWR:OK'; \
  fi) #[fg=white]| \
%H:%M:%S"

# 4. Launch Printer 1 (Top Pane)
tmux send-keys "bash ~/qidi_monitor.sh" C-m

# 5. Split and Launch Printer 2 (Bottom Pane)
tmux split-window -v
tmux send-keys "bash ~/makerselect_monitor.sh" C-m

# 6. Attach to the session
tmux attach-session -t printers
