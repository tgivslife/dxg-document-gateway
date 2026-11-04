groupadd xfer
useradd -M -s /usr/sbin/nologin -G xfer ext_xfer
useradd -M -s /usr/sbin/nologin -G xfer int_xfer
install -d -o root -g root -m 0755 /srv/xfer
install -d -o root -g xfer -m 2770 /srv/xfer/drop
