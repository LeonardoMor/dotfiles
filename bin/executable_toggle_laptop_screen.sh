#!/usr/bin/env bash

NAME="$(basename "$0")"

displays="$(kscreen-doctor --outputs | grep -c enabled)"

enable_builtin() {
	if ((displays > 1)); then
		kscreen-doctor output.eDP-1.enable output.eDP-1.mode.1920x1080@60 output.eDP-1.scale.1.25 output.DP-1.enable output.DP-1.mode.1920x1080@165 output.DP-1.position.1536,0
		exit
	fi
	kscreen-doctor output.eDP-1.enable
}

disable_builtin() {
	kscreen-doctor output.eDP-1.disable
}

disable_builtin
sleep 1
enable_builtin
