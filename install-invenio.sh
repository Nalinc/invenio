#!/bin/bash

readonly WORKDIR=$(pwd)
readonly USER="$USER"
readonly DB_NAME="invenio"
readonly DB_USER="invenio"

function message() {
	COLOR="\e[32m"
	RESET="\e[0m"
	echo -e "$COLOR[*] "$@"$RESET"
}


################
# Requirements #
################
message "Requirements"

# Database
sudo apt-get install -y mariadb-server libmariadbclient-dev
# Webserver
sudo apt-get install -y \
    python-pip redis-server python-dev libssl-dev libxml2-dev libxslt-dev \
    gnuplot clisp automake pstotext gettext
sudo pip install invenio-devserver nose plumbum
# System
sudo apt-get install -y git unzip wget


#############
# Uninstall #
#############

sudo rm /opt/invenio -r


###################
# Install Invenio #
###################
message "Install Invenio"

# Preparing Invenio build folder
cd "$WORKDIR/invenio"
mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME"

# Installing Invenio requirements
sudo pip install -r requirements.txt
#RUN sudo pip install -r requirements-extras.txt

# Building Invenio
aclocal
automake -a
autoconf
./configure 
make

# Preparing Invenio destination folders
sudo mkdir -p /opt/invenio
sudo chown $USER:$USER /opt/invenio
sudo ln -s /opt/invenio/lib/python/invenio /usr/local/lib/python2.7/dist-packages/invenio

# Installing Invenio and plugins
make install
make install-jquery-plugins

# Configuration
cp "$WORKDIR/invenio-invenio-local.conf" /opt/invenio/etc/invenio-local.conf

/opt/invenio/bin/inveniocfg --update-all
/opt/invenio/bin/inveniocfg --load-bibfield-conf


###################
# Create Database #
###################
message "Create Database"

export CFG_INSPIRE_BIBTASK_USER="admin"
sudo service mysql restart
sudo service redis-server restart
sleep 3

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost IDENTIFIED BY 'my123p\$ss'"
/opt/invenio/bin/inveniocfg --create-tables

/opt/invenio/bin/inveniocfg --create-demo-site
/opt/invenio/bin/inveniocfg --load-demo-records


#############
# Completed #
#############

echo "[*] Installation completed -" $(date +"%H:%M:%S %d/%m/%Y")
