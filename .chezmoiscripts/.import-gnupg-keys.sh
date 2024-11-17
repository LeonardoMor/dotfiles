#!/usr/bin/env bash

if gpg -K | grep -q 19E2D77D03858CB897E78CABFD14E47B11D7C460; then
	exit
fi

read -rp "Import GPG keys? [y/N] "

if ! [[ $REPLY =~ ^[Yy]$ ]]; then
	exit
fi

read -rp "Absolute path to the public key? " PUBLIC_KEY_PATH
read -rp "Absolute path to the private key? " PRIVATE_KEY_PATH

echo "Importing GPG keys..."
gpg --import "$PUBLIC_KEY_PATH"
gpg --import "$PRIVATE_KEY_PATH"
