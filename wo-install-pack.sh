#!/usr/bin/env bash
# -------------------------------------------------------------------------
#  WO-INSTALL-PACK - automated WordOps server setup script
# -------------------------------------------------------------------------
# Website:       https://virtubox.net
# FORKED
# GitHub:        https://github.com/VirtuBox/ee-nginx-setup
# This script is licensed under M.I.T
# -------------------------------------------------------------------------
# Version 1.0 - 2019-02-19
# -------------------------------------------------------------------------

CSI='\033['
CEND="${CSI}0m"
CGREEN="${CSI}1;32m"
CRED="${CSI}1;31m"


###Variaveis



###Checando usuario root

[ "$(id -u)" != "0" ] && {
    echo "Error: You must be root to run this script, please use the root user to install the software."
    echo ""
    echo "Use 'sudo su - root' to login as root"
    exit 1
}

### Make Sure Sudo available ###

    apt-get -y install sudo curl >>/dev/null 2>&1

##################################
# Welcome
##################################

echo -e "${CGREEN}
--------------------------------------------------------------------------
                Bem Vindo ao script Wo-instal-pack
 -------------------------------------------------------------------------
        WO-INSTALL-PACK - Script de Instalação do WordOps
 -------------------------------------------------------------------------
 FORKED         Este script é um fork do:
 GitHub:        https://github.com/VirtuBox/wo-nginx-setup
  Licença M.I.T
 -------------------------------------------------------------------------
 Github:        https://github.com/juanpvh/wo-install
 Script:        WO-INSTALL
 Atualização:   16-11-2019
 -------------------------------------------------------------------------
 ${CEND}"
 sleep 5
 clear 
##################################
# INSTALAÇÃO
##################################

#adicionar swap
    dd if=/dev/zero of=/var/swap bs=1k count=1024k
    mkswap /var/swap
    swapon /var/swap
    echo '/var/swap swap swap defaults 0 0' | sudo tee -a /etc/fstab
    free -m
###

###Pacotes do Sistemas Atualizados

    apt-get update -y 
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get autoremove -y --purge
    apt-get autoclean -y

###

###Instalação de Serviços Adicionais

    apt-get install haveged jpegoptim optipng webp curl mutt git zip unzip htop nload jq nmon tar gzip ntp ntpdate gnupg gnupg2 wget pigz tree ccze mycli screen -y
    ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
###

### ntp time

    systemctl enable ntp

###

### increase history size

    export HISTSIZE=10000
###

###Clonando repositorio

    
    git clone https://github.com/juanpvh/wo-install.git $HOME/wo-install || git -C $HOME/wo-install pull origin master
        
###

### Redis transparent_hugepage

    echo never >/sys/kernel/mm/transparent_hugepage/enabled

###

### Instalando Rclone e wo-cli
echo "INSTALANDO RCLONE..."
    [ -e /usr/bin/rclone ] && echo "Rclone Existe ⚡️" || curl https://rclone.org/install.sh | sudo bash

echo "INSTALANDO WO-CLI.."
    [ -e /usr/local/bin/wo-cli ] && echo "wo-cli Existe ⚡️" || wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
 chmod +x /usr/local/bin/wo-cli

#sed -i "s/BACKUPS=BK/BACKUPS=$USER/" /usr/local/bin/wo-cli

(crontab -l; echo "0 2 * * * bash /usr/local/bin/wo-cli -b >> /var/log/wo-cli.log 2>&1") | crontab -
###

################################################
###Instalação do WordOps
###############################################

    if [ -e /usr/local/bin/wo ]; then

        echo "WordOps Instalado"

    else

        wget -qO wo wops.cc && sudo bash wo
        source /etc/bash_completion.d/wo_auto.rc
        rm -rf wo
    
    fi

###

###Instalando Pack adicional do WordOps
    if [ -e /usr/local/bin/wo ]; then

        /usr/local/bin/wo stack install
        /usr/local/bin/wo stack install --clamav
	    apt-get install php7.2-intl
       
    
    fi
###

###Configurando adicionais acesso www-data shell

    # change www-data shell
    usermod -s /bin/bash www-data

    if [ ! -f /etc/bash_completion.d/wp-completion.bash ]; then
        # download wp-cli bash-completion
        wget -qO /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
 
  
        #Customize WordPress installation locale

         cp -f $HOME/wo-install/etc/config.yml ~/.wp-cli/config.yml

    fi

    if [ ! -f /var/www/.profile ] && [ ! -f /var/www/.bashrc ]; then
        # create .profile & .bashrc for www-data user
        cp -f $HOME/wo-install/var/www/.profile /var/www/.profile
        cp -f $HOME/wo-install/var/www/.bashrc /var/www/.bashrc

        # set www-data as owner
        chown www-data:www-data /var/www/.profile
        chown www-data:www-data /var/www/.bashrc
    fi

###



###Compilando a Pilha Nginx-ee
    if [ -f /usr/sbin/nginx ]; then
    
        cp -f $HOME/wo-install/etc/nginx/conf.d/upstream.conf /etc/nginx/conf.d/upstream.conf
        cp -f $HOME/wo-install/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222
        #sed -i "s/memory_limit = 128M/memory_limit = 256M/" /etc/php/7.2/fpm/php.ini
        #cp -f $HOME/wo-install/etc/php/7.3/fpm/php.ini /etc/php/7.3/fpm/php.ini
    fi
###

###Configuração adicional  fail2ban...

   # Add fail2ban configurations
    cp -rf $HOME/wo-install/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
    cp -rf $HOME/wo-install/etc/fail2ban/jail.d/* /etc/fail2ban/jail.d/

    fail2ban-client reload

###Instalando Monit...
if [ -f /usr/local/bin/monit ]; then

        echo "Monit Instalando"

    else

        apt-get -y autoremove monit --purge
        rm -rf /etc/monit/
        apt-get install -y git build-essential libtool openssl automake byacc flex zlib1g-dev libssl-dev     autoconf bison libpam0g-dev
        cd ~
        wget https://mmonit.com/monit/dist/monit-5.25.2.tar.gz
        tar zxvf monit-*.tar.gz
        rm -rf monit-5.25.2.tar.gz
        cd monit-*
        ./bootstrap
        ./configure
        make && make install
        mkdir /etc/monit/
        mkdir /etc/monit/monit.d/
        mkdir /etc/monit/conf-enable/
        cd ~
        cp -rf $HOME/wo-install/etc/monitrc /etc/
        chmod 0600 /etc/monitrc
        ln -s /etc/monitrc /etc/monit/monitrc
        #regras
        cp -rf $HOME/wo-install/etc/monit/monit.d/* /etc/monit/monit.d/
        cp -rf $PWD/wo-install/etc/monit.service /lib/systemd/system/monit.service
        systemctl enable monit
        #linkar
        ln -s /etc/monit/monit.d/* /etc/monit/conf-enable/

        #mysql -e "CREATE USER 'monit'@'localhost' IDENTIFIED BY 'mysecretpassword';" > /dev/null 2>&1
        #mysql -e "FLUSH PRIVILEGES"
        #systemctl restart mysql
        monit
        monit reload

        

fi
	
###


### Install Rkhunter

if [ -z "$(command -v rkhunter)" ]; then
	
	apt-get install rkhunter -y

	sed -i 's/UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
	sed -i 's/MIRRORS_MODE=1/UPDATE_MIRRORS=0/' /etc/rkhunter.conf
	sed -i 's/WEB_CMD="\/bin\/false"/WEB_CMD=""/' /etc/rkhunter.conf

	sed -i 's/CRON_DAILY_RUN=""/CRON_DAILY_RUN="true"/' /etc/default/rkhunter
	sed -i 's/CRON_DB_UPDATE=""/CRON_DB_UPDATE="true"/' /etc/default/rkhunter
	sed -i 's/APT_AUTOGEN="false"/APT_AUTOGEN="true"/' /etc/default/rkhunter
	rkhunter -C
	rkhunter --update
	rkhunter --versioncheck
	rkhunter --propupd
	rkhunter --check --sk
	
fi



###Instalando Nanorc...

    chmod +x $HOME/wo-install/var/www/nanorc.sh
    bash $HOME/wo-install/var/www/nanorc.sh

    wget -O mysqldump.sh virtubox.net/mysqldump
    chmod +x mysqldump.sh

###


###Difinindo regras do firewall - ufw

ufw logging low
ufw default allow outgoing
ufw default deny incoming
ufw allow 4444
ufw allow 53
ufw allow http
ufw allow https
ufw allow 123
ufw allow 68
ufw allow 546
ufw allow 873
ufw allow 22222
ufw allow 19999
ufw allow 2812
ufw allow 49000:50000/tcp

###


###Instalando Script de otimização de imagens...

cp $HOME/.img-optimize/optimize.sh /usr/local/bin/img-optimize
chmod +x chmod +x /usr/local/bin/img-optimize

cp $HOME/.img-optimize/crons/jpg-png-cron.sh /etc/cron.weekly/jpg-png-cron
cp $HOME/.img-optimize/crons/jpg-png-cron.sh /etc/cron.weekly/webp-cron

chmod + x /etc/cron.weekly/jpg-png-cron
chmod + x /etc/cron.weekly/webp-cron

 

#ATIVANDO FIREWALL
ufw reload
echo "y" | ufw enable

###Limpando Instalação...

apt-get -y autoremove php5.6-fpm php5.6-common --purge
apt-get -y autoremove php7.0-fpm php7.0-common --purge
apt-get -y autoremove php7.1-fpm php7.1-common --purge
cd ~
rm -rf wo-install nginx-build.sh wo-install-pack.sh

###
clear

[ -f /usr/local/bin/wo ] && echo -e "${CGREEN}WordOps Instalado${CEND}   [${CGREEN}OK${CEND}]"
echo -e "${CGREEN}Finalizando...${CEND}   [${CGREEN}OK${CEND}]"
###
ADDRESS=$(hostname -I | awk '{ print $1}')
echo " "
echo " Optimized Wordops was setup successfully! "
echo " Painel Principal: https://$ADDRESS:22222"
echo " Para Configurar o Rclone digite: rclone config"
