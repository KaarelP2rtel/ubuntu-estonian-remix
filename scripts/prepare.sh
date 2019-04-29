#!/bin/bash -e
set -x
PS4='Line ${LINENO}: '
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C.UTF-8
#needed for some package installation
service dbus start

#configure connectivity
echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

#add repositories
cat >> /etc/apt/sources.list.d/estmix.list <<EOF
deb ${MIRROR} ${RELEASE} universe
deb ${MIRROR} ${RELEASE}-updates universe
deb ${MIRROR} ${RELEASE} multiverse
deb ${MIRROR} ${RELEASE}-updates multiverse
deb http://archive.canonical.com/ubuntu ${RELEASE} partner
deb ${MIRROR} ${RELEASE}-security universe
deb ${MIRROR} ${RELEASE}-security multiverse
deb http://download.videolan.org/pub/debian/stable/ / #libdvdcss2
deb [arch=amd64] https://downloads.iridiumbrowser.de/deb/ stable main #Iridium Browser
deb [arch=amd64] https://s3-us-west-2.amazonaws.com/brave-apt $RELEASE main #Brave Browser
EOF

#add some additional repositories before updating package list
#
# Iridium Browser (based on Chromium, very fast and secure) https://iridiumbrowser.de/downloads/linux.html
wget -qO - https://downloads.iridiumbrowser.de/ubuntu/iridium-release-sign-01.pub | sudo apt-key add -

#add-apt-repository "deb [arch=amd64] https://downloads.iridiumbrowser.de/deb/ stable main"
#
# Brave Browser https://github.com/brave/browser-laptop/blob/master/docs/linuxInstall.md
wget -qO - https://s3-us-west-2.amazonaws.com/brave-apt/keys.asc | sudo apt-key add -
#add-apt-repository "deb [arch=amd64] https://s3-us-west-2.amazonaws.com/brave-apt $RELEASE main"
#
# libdvdcss2 https://www.videolan.org/developers/libdvdcss.html
wget -qO - http://download.videolan.org/pub/debian/videolan-apt.asc | sudo apt-key add -
#add-apt-repository "deb http://download.videolan.org/pub/debian/stable/ /"
#
# Inkscape https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable

#update package lists
apt-get update
