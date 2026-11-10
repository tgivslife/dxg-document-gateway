#!/usr/bin/env bash
# setup-xfer-dirs.sh <sender-account> <receiver-account>
# dmz-import: setup-xfer-dirs.sh ext_xfer int_xfer
# dmz-export: setup-xfer-dirs.sh int_xfer ext_xfer
# Only the sender can write to packages/. The receiver can read and nothing else.
set -euo pipefail
sender=$1; receiver=$2

groupadd xfer-read
useradd -M -s /usr/sbin/nologin "$sender"
useradd -M -s /usr/sbin/nologin -G xfer-read "$receiver"
install -d -o root -g root -m 0755 /srv/xfer
install -d -o "$sender" -g xfer-read -m 2750 /srv/xfer/packages
