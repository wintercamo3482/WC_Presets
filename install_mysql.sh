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
install_mysql() {
	echo -e "[INFO ] Install mysql-server"

	if dpkg -s mysql-server >/dev/null 2>&1; then
		echo -e "[INFO ] mysql-server already installed"
		return 0
	else
		if sudo apt install -y mysql-server; then
			echo -e "${GREEN}[INFO ] Success install mysql-server${RESET}"
		else
		    echo -e "${RED}[ERROR] Failed to install mysql-server${RESET}"
		    return 1
	fi
		
    fi

    echo -e "[INFO ] Enable and start mysql-service"
    
    sudo systemctl enable mysql
    sudo systemctl start mysql
    
    if systemctl is-active --quiet mysql; then
        echo -e "${GREEN}[INFO ] mysql service running${RESET}"
    else
        echo -e "${YELLOW}[WARN] mysql service not running${RESET}"
        return 1
    
    fi
}
# --------------------------------------
echo -e "Install MySQL for SCEU"

sudo -v || exit 1
install_mysql || exit 1
