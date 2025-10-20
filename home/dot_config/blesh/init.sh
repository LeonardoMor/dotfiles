# Faces
ble-face auto_complete=fg=gray

# Key bindings
ble-bind -m 'auto_complete' -f 'M-l' 'auto_complete/insert-cword'
ble-bind -m 'emacs' -f 'M-h' -
ble-bind -m 'auto_complete' -f 'M-h' 'auto_complete/@end insert'

# Options
bleopt prompt_ps1_transient=same-dir:trim
bleopt prompt_ps1_final='$(starship module character)'
bleopt prompt_rps1_final='$(starship module cmd_duration)'
bleopt exec_errexit_mark=
bleopt exec_elapsed_mark=
