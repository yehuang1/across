#!/bin/bash
# Usage:
#   curl https://raw.githubusercontent.com/mixool/across/master/ssh/securityssh.sh | bash

# only root can run this script
[[ $EUID -ne 0 ]] && echo "Error, This script must be run as root!" && exit 1

# custom port
echo; echo "$(date) securing your ssh server with custom port..."
SSH_PORT=${SSH_PORT:-n}
while ! [[ ${SSH_PORT} =~ ^[0-9]+$ ]]; do
    read -p "custom ssh port: " SSH_PORT </dev/tty
done

# custom rsa_pub_key
echo; echo "$(date) securing your ssh server with authorized_keys..."
RSA_PUB_KEY=${RSA_PUB_KEY:-n}
while ! [[ ${RSA_PUB_KEY} =~ ssh-rsa* ]]; do
    read -p "custom public key: " RSA_PUB_KEY </dev/tty
done

# active
echo; echo "$(date) waiting custom confirm..."; echo "port: ${SSH_PORT}"; echo "rsa_pub_key: ${RSA_PUB_KEY}"
echo; read -p "is_confirm? [y/n]" is_confirm
if [[ ${is_confirm} == "y" || ${is_confirm} == "Y" ]]; then
    # backup config
    bakname=$(date +%N) && cp /etc/ssh/sshd_config /etc/ssh/sshd_config_$bakname
    # change port
    if grep -qwE "^Port\ [0-9]*" /etc/ssh/sshd_config; then
        sed -i "s/^Port\ [0-9]*/Port\ ${SSH_PORT}/g" /etc/ssh/sshd_config
    else
        sed -i "/^#Port\ [0-9]*/a Port\ ${SSH_PORT}" /etc/ssh/sshd_config
    fi
    # set root rsa_pub_key login without-password
    [[ ! -d "/root/.ssh" ]] && mkdir -p "/root/.ssh" && chmod 700 /root/.ssh
    echo $RSA_PUB_KEY >>/root/.ssh/authorized_keys
    sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys
    sed -i "s/PermitRootLogin.*/PermitRootLogin without-password/g" /etc/ssh/sshd_config
    # restart ssh
    service ssh restart
    # info
    echo; echo "$(date) ssh port updated to ${SSH_PORT}, please login with authorized_keys, backup file: /etc/ssh/sshd_config_$bakname"
else
    echo; echo "canceled..."
fi
