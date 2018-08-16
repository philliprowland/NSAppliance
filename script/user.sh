#!/bin/bash

date > /etc/box_build_time

SSH_USER=${SSH_USERNAME:-phillip}
SSH_PASS=${SSH_PASSWORD:-packer}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}
SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlVNhLV0Pv7beWzgdGdWBfzzWOZpSQpPubcmPGBGMUHXy32Nn98mJV/otJpoHzoMyz7x7BosKtDx0PEubSQNnTvFLbTlvJJ0+ZBIeZIiCWjl2ebV8nwBBc287fDne4Ku2lXlWJGce32lvchgu+7olRHdjrhDGkt+xK7SwGgm7kbeMpsSjhWkfMYDlt++BDKcwcMWen4QEcbBPcNsewKxnmjAGztEZAwvevbS7O9ddATh3JeauYMlKw24fIkAxOB7uQT5EwntqpmAKJGUIRuWIgzFBnaJfTouzvIwdVDkNoUV4kQ8/rMM8n3aEUH57Ef7FbrBjilKVj2wgNZShqAOmF phillip@phillip-ThinkPad-T4"

# Packer passes boolean user variables through as '1', but this might change in
# the future, so also check for 'true'.
if [ "$INSTALL_SSH_KEY" = "true" ] || [ "$INSTALL_SSH_KEY" = "1" ]; then
    # Create user (if not already present)
    if ! id -u $SSH_USER >/dev/null 2>&1; then
        echo "==> Creating $SSH_USER user"
        /usr/sbin/groupadd $SSH_USER
        /usr/sbin/useradd $SSH_USER -g $SSH_USER -G sudo -d $SSH_USER_HOME --create-home
        echo "${SSH_USER}:${SSH_PASS}" | chpasswd
    fi

    # Set up sudo
    echo "==> Giving ${SSH_USER} sudo powers"
    echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/$SSH_USER
    chmod 440 /etc/sudoers.d/$SSH_USER

    # Fix stdin not being a tty
    if grep -q -E "^mesg n$" /root/.profile && sed -i "s/^mesg n$/tty -s \\&\\& mesg n/g" /root/.profile; then
      echo "==> Fixed stdin not being a tty."
    fi

    echo "==> Installing user key"
    mkdir $SSH_USER_HOME/.ssh
    chmod 700 $SSH_USER_HOME/.ssh
    cd $SSH_USER_HOME/.ssh

    echo "${SSH_PUB_KEY}" > $SSH_USER_HOME/.ssh/authorized_keys
    chmod 600 $SSH_USER_HOME/.ssh/authorized_keys
    chown -R $SSH_USER:$SSH_USER $SSH_USER_HOME/.ssh
fi
