#!/usr/bin/env bash

# --------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
# --------------------------------------
update_packages() {
	echo -e "[INFO ] apt update"

	if sudo apt update; then
		echo -e "${GREEN}[INFO ] Successfully updated apt${RESET}"
	else
		echo -e "${RED}[ERROR] Failed to update apt${RESET}"
		return 1
	fi
}
# --------------------------------------
install_vim() {
	echo -e "[INFO ] Install vim"

	if dpkg -s vim >/dev/null 2>&1; then
		echo -e "[INFO ] vim already installed"
		return 0
	else
		if sudo apt install -y vim; then
			echo -e "${GREEN}[INFO ] Success install vim${RESET}"
		else
		    echo -e "${RED}[ERROR] Failed to install vim${RESET}"
		    return 1
		fi
    fi
}
# --------------------------------------
install_net_tools() {
    echo -e "[INFO ] Install net-tools"

    if dpkg -s net-tools >/dev/null 2>&1; then
        echo -e "[INFO ] net-tools already installed"
        return 0
    fi

    if sudo apt install -y net-tools; then
        echo -e "${GREEN}[INFO ] Success install net-tools${RESET}"
    else
        echo -e "${RED}[ERROR] Failed to install net-tools${RESET}"
        return 1
    fi
}
# --------------------------------------
install_openssh() {
	echo -e "[INFO ] Install open-ssh"

	if dpkg -s openssh-server >/dev/null 2>&1; then
		echo -e "[INFO ] open-ssh already installed"
	else
		if sudo apt install -y openssh-server; then
		    echo -e "${GREEN}[INFO ] Success install openssh-server${RESET}"
		else
		    echo -e "${RED}[ERROR] Failed to install openssh-server${RESET}"
		    return 1
		fi
    fi

	sudo systemctl enable ssh && sudo systemctl start ssh
	
	if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}[INFO ] ssh service running${RESET}"
    else
        echo -e "${YELLOW}[WARN] ssh service not running${RESET}"
        return 1
    fi
}
# --------------------------------------
install_samba() {
	echo -e "[INFO ] Install samba"

	local NAME="${SUDO_USER:-$USER}"
    local CONF="/etc/samba/smb.conf"

	if dpkg -s samba >/dev/null 2>&1; then
        echo -e "[INFO ] samba already installed"
        return 0
    else
		if sudo apt install -y samba; then
		    echo -e "${GREEN}[INFO ] Success install samba${RESET}"
		else
		    echo -e "${RED}[ERROR] Failed to install samba${RESET}"
		    return 1
		fi
    fi

	echo -e "[INFO ] Append samba share to smb.conf"
	sudo bash -c "cat >> '${CONF}' <<EOF

[${NAME}]
    path = /home/${NAME}/
    valid user = ${NAME}
    browseable = yes
    writable = yes
    create mask = 0755
    directory mask = 0755
EOF" || {
        echo -e "${RED}[ERROR] Failed to update smb.conf${RESET}"
        return 1
    }

	echo -e "${GREEN}[INFO ] smb.conf updated${RESET}"

	echo -e "[INFO ] Add samba user: ${NAME}"
    if sudo smbpasswd -a "${NAME}"; then
        echo -e "${GREEN}[INFO ] smbpasswd set${RESET}"
    else
        echo -e "${RED}[ERROR] smbpasswd failed${RESET}"
        return 1
    fi

    echo -e "[INFO ] Allow Samba through UFW"
    sudo ufw allow 'Samba' >/dev/null 2>&1 || true

    echo -e "[INFO ] Restart smbd"
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart smbd
    else
        sudo /etc/init.d/smbd restart
    fi

	echo -e "${GREEN}[INFO ] Samba setup completed${RESET}"
}
# --------------------------------------
echo -e "Linux-18 Base Presets"

sudo -v || exit 1
update_packages || exit 1
install_vim || exit 1
install_net_tools || exit 1
install_openssh || exit 1
install_samba || exit 1

sudo reboot
