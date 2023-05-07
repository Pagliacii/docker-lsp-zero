#!/usr/bin/env bash

set -euxo pipefail

echo "**** add password to root user ****"
echo "root:${ROOT_PASSWORD:-roottoor}" | chpasswd

echo "**** setup sudoers ****"
if [ "$SUDO_ACCESS" = true ]; then
	echo "%wheel  ALL=(ALL:ALL) NOPASSWD: ALL" >>/etc/sudoers
else
	echo "%wheel  ALL=(ALL:ALL) ALL" >>/etc/sudoers
fi

echo "**** setup openssh ****"
sed -i 's/^UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

if [ "$PASSWORD_ACCESS" = true ]; then
	echo "**** enable password auth ****"
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
else
	echo "**** disable password auth ****"
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

PORT=${PROT:-2222}
echo "**** change port to $PORT ****"
sed -i "s/#Port 22/Port $PORT/g" /etc/ssh/sshd_config

USERID=${USERID:-850}
USERNAME=${USERNAME:-jason}
PASSWORD=$(openssl passwd -6 ${PASSWORD:-mysecretpassword})
echo "**** add user: $USERNAME ****"
useradd -r \
	-u $USERID \
	-G wheel \
	-s /usr/bin/bash \
	-m $USERNAME \
	-d /home/$USERNAME \
	-p $PASSWORD

if [ -n "${PUBLICKEY}" ]; then
	echo "**** save public key to user config ****"
	mkdir -p "/home/$USERNAME/.ssh"
	echo "${PUBLICKEY}" >"/home/$USERNAME/.ssh/authorized_keys"
	chown -R $USERNAME:$USERNAME "/home/$USERNAME/.ssh"
fi

echo "**** setup neovim ****"
mkdir -p "/home/$USERNAME/.config"
cp -r "/config/nvim" "/home/$USERNAME/.config/nvim"
chown -R $USERNAME:$USERNAME "/home/$USERNAME/.config/nvim"
rm -rf "/config"

echo "**** init neovim ****"
sudo -u $USERNAME -H bash -c "nvim --headless -c 'LspInstall lua_ls' -c 'quit'"

echo "**** start sshd on daemon ****"
/usr/sbin/sshd -D
