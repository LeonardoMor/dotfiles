#!/bin/bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"${HOME}/.config"}"

# Install Tmux Plugin Manager
# You still need to open tmux and do prefix + I
git clone https://github.com/tmux-plugins/tpm "${XDG_CONFIG_HOME}/tmux/plugins/tpm"
