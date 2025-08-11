#!/usr/bin/env -S sed -i'' -Ef
#
# Edit /etc/ssh/sshd_config and disable password authentication.

s/^\#?(PasswordAuthentication|ChallengeResponseAuthentication|UsePAM) +(no|yes)/\1 no/
s/^\#?(PubkeyAuthentication) +(no|yes)/\1 yes/
