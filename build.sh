#!/bin/sh

set -e

# Run this script from within a booted SystemRescue

# Set environment vars first. Note that we can't make these anything -- best to stick to tmpfs
TEMP_USR=makepkguser

SYSRESCUE_EXTRACT_DIR=/tmp/sysrescue/extracted
SYSRESCUE_DIR=$(dirname "$SYSRESCUE_EXTRACT_DIR")
AIROOTFS_UNPACK_DIR=/tmp/airootfs_unpacked
PACKAGE_DIR=/tmp/packages

ISO_NAME="ACASLive.iso"

# Packages to install into the second SRM on top of stock SystemRescue
### NOTE: jdk-openjdk is <450MB. Remove it and reconfigure 
PACMAN_PKGS="git \
            base-devel \
            fakeroot \
            ntfs-3g \
            rpmextract \
            open-vm-tools \
            python-pip \
            jdk-openjdk \
            python-pyserial \
            nmap"

PACMAN_PKGS_TO_REMOVE="timeshift \
                      lftp \
                      yubico-c \
                      yubico-c-client \
                      yubikey-manager \
                      yubikey-personalization \
                      yubikey-personalization-gui \
                      qtpass \
                      keepassxc \
                      x11vnc \
                      geany \
                      stoken \
                      openconnect \
                      pulseaudio-alsa \
                      openvpn \
                      networkmanager-openvpn \
                      xfce4-pulseaudio-plugin" # need to rebuild config.tar.gz
#                       remmina" # add this line to remove VNC viewing capability

#### Note: we cannot remove avahi, but we can disable the service. this will cause us to lose samba, but whatever
####       look for the line below: `ln -s /dev/null /etc/systemd/system/avahi-daemon.service`

#####################################################
#                Unpack SysRescue                   #
#####################################################

# unpack the airootfs SRM
mkdir -p "$SYSRESCUE_EXTRACT_DIR"
cd "$SYSRESCUE_DIR"
sysrescue-customize --unpack --source=/dev/sr0 --dest="$SYSRESCUE_EXTRACT_DIR"
mkdir -p "$AIROOTFS_UNPACK_DIR"
unsquashfs -d "$AIROOTFS_UNPACK_DIR" "$SYSRESCUE_EXTRACT_DIR/filesystem/sysresccd/x86_64/airootfs.sfs"

# move the build files from /tmp into the extracted srm
mv /tmp/airootfs "$AIROOTFS_UNPACK_DIR/tmp/airootfs"
mv /tmp/modules "$AIROOTFS_UNPACK_DIR/tmp/opt"

#####################################################
#               Customize airootfs                  #
#####################################################

# Change dirs instead of chroot due to issues. We'll relatively reference this path the entire time
cd "$AIROOTFS_UNPACK_DIR"

# remove pacman packages
chroot "$AIROOTFS_UNPACK_DIR"
pacman --noconfirm -R "$PACMAN_PKGS_TO_REMOVE"
exit

# update firefox policies
mv ./tmp/airootfs/firefox_policies.json ./opt/firefox-esr/distribution/policies.json

# set XFCE configurations for root (dark mode and panel)
rm -rf ./root/.config
tar -zxvf "./tmp/airootfs/config.tar.gz" -C ./root/

# remove the firewall (done in YAML defaults below)
# rm -f ./etc/systemd/system/multi-user.target.wants/iptables.service
# rm -f ./etc/systemd/system/multi-user.target.wants/ip6tables.service

# disable avahi
ln -s /dev/null /etc/systemd/system/avahi-daemon.service

# modify hosts file and hostname (can also be done in yaml but i want it here)
cat > "./etc/hosts" <<EOF
127.0.0.1   localhost acas acasvm acaslive sysrescue
::1         localhost acas acasvm acaslive sysrescue
EOF

echo 'acas' > "./etc/hostname"

# modify "$AIROOTFS_UNPACK_DIR/root/.bashrc"
echo 'alias l="ls"' >> ./root/.bashrc
echo 'alias la="ls -la"' >> ./root/.bashrc
echo 'alias activate="source /root/.venv/bin/activate"' >> ./root/.bashrc
cat >> ./root/.bashrc <<EOF

function https-server() {
    ip="0.0.0.0"
    port="\$1"
    t=\$(mktemp -d)
    openssl req -x509 -newkey rsa:3072 -nodes -keyout \$t/k -out \$t/c -sha256 -days 5 -subj "/CN=localhost" 2>/dev/null | grep ignoreoutput
    echo "Serving HTTPS at https://\$ip:\$port/ ..."
    python -c "import http.server, ssl; \\
    httpd = http.server.HTTPServer(('\$ip', \$port), http.server.SimpleHTTPRequestHandler); \\
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH); \\
    ctx.load_cert_chain(certfile='\$t/c', keyfile='\$t/k'); \\
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True); \\
    httpd.serve_forever();"
    shred \$t/k||true
    rm -r \$t
}

function http-server() {
    python -m http.server \$1
}

EOF


#### setup autorun script & service
mv ./tmp/airootfs/autorun.sh ./usr/local/bin/autorun.sh
chmod 744 ./usr/local/bin/autorun.sh
mv ./tmp/airootfs/autorun.service ./usr/lib/systemd/system/autorun.service
ln -s /usr/lib/systemd/system/autorun.service ./etc/systemd/system/multi-user.target.wants/autorun.service

################## Add NessusAPI ##################

mv ./tmp/opt/NessusAPI ./opt/

# we have to install venv since pytenable is not an arch-native package
python -m venv ./root/.venv
source ./root/.venv/bin/activate
# python -m pip install --upgrade pip
pip install pytenable
deactivate

echo 'alias nessus-configure="/root/.venv/bin/python /opt/NessusAPI/nessus-configure.py"' >> ./root/.bashrc
echo 'alias nessus-policy-update="/root/.venv/bin/python /opt/NessusAPI/nessus-policy-update.py"' >> ./root/.bashrc

########## Add Networkctl + Helper Scripts ##########

mv ./tmp/opt/TenableCore/scripts/bin ./opt/scripts
mv ./tmp/opt/TenableCore/NetworkManager/*.nmconnection ./etc/NetworkManager/system-connections/
chmod 600 ./etc/NetworkManager/system-connections/*.nmconnection

for file in $(ls -1 ./opt/scripts/ | grep \.sh) ; do
    chmod 755 "./opt/scripts/$file"
    # since networkctl exists on archlinux, we leave the '.sh extension'
    ln -s "/opt/scripts/$file" "./usr/bin/$file"
done

################ Add Notes/Procedures ################
mkdir -p ./root/Desktop/
mv ./tmp/opt/Notes ./root/Desktop/Procedures

################################## ***************** ##################################
############################# TODO: ADD OSD BUILD SCRIPTS #############################
################################## ***************** ##################################

## cleanup build files from airootfs/tmp
rm -rf ./tmp/airootfs ./tmp/opt

################## Repack airootfs ##################

cd "$SYSRESCUE_DIR"
rm "$SYSRESCUE_DIR/extracted/filesystem/sysresccd/x86_64/airootfs.sfs"
mksquashfs "$AIROOTFS_UNPACK_DIR" "$SYSRESCUE_DIR/extracted/filesystem/sysresccd/x86_64/airootfs.sfs"

#####################################################
#               Modify Boot Defaults                #
#####################################################

# modify YAML defaults
cat >"$SYSRESCUE_EXTRACT_DIR/filesystem/sysrescue.d/100-defaults.yaml" <<EOF
---
global:
    copytoram: true
    checksum: false
    loadsrm: true
    dostartx: true
    dovnc: false
    noautologin: false
    nofirewall: true

autorun:
    ar_disable: true

sysconfig:
    bash_history:
        100: "setkmap"

EOF

#####################################################
#                Prepare Pacman SRM                 #
#####################################################

mkdir -p "$PACKAGE_DIR"
cd "$PACKAGE_DIR"
chmod 777 "$PACKAGE_DIR"

# update pacman db & install packages
pacman --noconfirm -Sy "$PACMAN_PKGS"

################## Install Nessus ##################

useradd "$TEMP_USR"
echo "$TEMP_USR ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$TEMP_USR"

su "$TEMP_USR" -c "git clone https://aur.archlinux.org/nessus.git"
cd nessus
su "$TEMP_USR" -c "echo Y | makepkg -si"
cd -

rm -f "/etc/sudoers.d/$TEMP_USR"
userdel "$TEMP_USR"

# prepare the SRM
cowpacman2srm -s prepare

# customize the SRM
cd /tmp/srm_content
mkdir -p ./etc/systemd/system
ln -s /usr/lib/systemd/system/nessusd.service ./etc/systemd/system/nessusd.service

# close the srm and put it with airootfs.sfs
cowpacman2srm -s create "$SYSRESCUE_EXTRACT_DIR/filesystem/sysresccd/ACAS.srm"

#####################################################
#               Repack SystemRescue                 #
#####################################################

sysrescue-customize --rebuild --source="$SYSRESCUE_EXTRACT_DIR" --dest="$SYSRESCUE_DIR/$ISO_NAME"

echo "System Rescue ISO built to: $SYSRESCUE_DIR/$ISO_NAME"
echo "Make sure to copy this image back to your host and test it before deploying it to production"

cd "$SYSRESCUE_DIR"

exit 0