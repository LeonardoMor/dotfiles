#!/usr/bin/env bash

read -rp "Import GPG keys? [y/N] "

if ! [[ $REPLY =~ ^[Yy]$ ]]; then
	exit
fi

read -rp "Absolute path to the public key? " PUBLIC_KEY_PATH
read -rp "Absolute path to the private key? " PRIVATE_KEY_PATH

echo "Importing GPG keys..."
gpg --import "$PUBLIC_KEY_PATH"
gpg --import "$PRIVATE_KEY_PATH"
