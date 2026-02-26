#!/bin/bash

# set -e , set -u , set -o
set -e 
set -u 
set -o pipefail

LOG_FILE="/var/log/server_bootstrap.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "i am seerver bootstrap .sh " 

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

NEW_USER="devops" 
PACKAGES="git curl htop dnf-plugins-core"


update_system(){
	echo "Updating System ..."
	sudo dnf update -y && sudo dnf update -y
}

install_packages(){
	echo "Installing custom packages ..."
	sudo dnf install -y $PACKAGES
}

custom_repo_mirrors(){
	echo "Adding custom repos .."
	sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
}

create_user(){
	if id "$NEW_USER" &>/dev/null; then
		echo "User already exists"
	else
		sudo useradd -m -s /bin/bash $NEW_USER
		sudo usermod -aG wheel $NEW_USER
		echo "User created and added to sudo group"
	fi
}

enable_services(){
	systemctl enable docker 
	systemctl start docker
}

system_info(){
	echo "CPU info: "
	lscpu | grep "Model name"
	
	echo "Memory Info"	
	free -h 
	
	echo "Disk Info"
	df -h
}

main(){
	update_system
	install_packages
	create_user	
	custom_repo_mirrors
	enable_services
	system_info
}

main
