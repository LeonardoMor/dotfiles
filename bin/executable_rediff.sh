#!/usr/bin/env bash

NAME="$(basename "$0")"

help() {
	cat <<EOF
usage:	$NAME ACTUAL IMPOSTOR
	$NAME -h
	
Given two directories with very similar structure and files, the files that differ.
EOF
}

while getopts 'h' opt; do
	case "$opt" in
		h)
			help
			exit 0
			;;
		*)
			help >&2
			exit 1
			;;
	esac
done

actual="$1" impostor="$2"
while read -r f; do
	if ! diff -u "$f" "${impostor}/${f#"${actual}"/}" >/dev/null 2>&1; then
		diff -u "$f" "${impostor}/${f#"${actual}"/}"
	fi
done < <(find "$actual" -type f) | bat --plain | less -R
