#!/usr/bin/env bash
set -euo pipefail

for g in dxg-intake dxg-outtake dxg-email dxg-manual; do groupadd --system "$g"; done
useradd --system -M -s /usr/sbin/nologin -G dxg-intake,dxg-outtake,dxg-email dxg-mail
useradd --system -M -s /usr/sbin/nologin -G dxg-intake,dxg-outtake,dxg-manual dxg-web
useradd --system -M -s /usr/sbin/nologin -G dxg-intake dxg-pipeline
useradd --system -M -s /usr/sbin/nologin -G dxg-outtake,dxg-email,dxg-manual dxg-release

install -d -o root -g dxg-intake -m 2770 /srv/dxg/intake
install -d -o root -g dxg-intake -m 2770 /srv/dxg/intake/.incoming
install -d -o root -g dxg-intake -m 2770 /srv/dxg/intake/ready
install -d -o dxg-pipeline -g dxg-intake -m 2750 /srv/dxg/intake/processing
install -d -o dxg-pipeline -g dxg-intake -m 2750 /srv/dxg/intake/rejected

install -d -o dxg-release -g dxg-release -m 0750 /srv/dxg/outtake/.incoming
install -d -o root -g root -m 0755 /srv/dxg/outtake/ready
install -d -o dxg-release -g dxg-email -m 2770 /srv/dxg/outtake/ready/email
install -d -o dxg-release -g dxg-manual -m 2770 /srv/dxg/outtake/ready/manual
install -d -o root -g dxg-outtake -m 2770 /srv/dxg/outtake/results
