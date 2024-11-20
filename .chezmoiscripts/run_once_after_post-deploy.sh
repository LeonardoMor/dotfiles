#!/usr/bin/env bash

if gh --version >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
	gh auth login
fi
