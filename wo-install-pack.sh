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

[ -z "$(command -v sudo)" ] && { apt-get -y install sudo >>/dev/null 2>&1; }
[ -z "$(command -v curl)" ] && { apt-get -y install curl >>/dev/null 2>&1; }



##################################
# help
##################################

_help() {
    echo "WO-INSTALL.PACK - automated WordOps server setup script"
    echo "Usage: ./wo-install-pack.sh [options]"
    echo "  Options:"
    echo "       --remote-mysql ..... install mysql-client for remote mysql access"
    echo "       -i | --interactive ..... interactive installation mode"
    echo "       --proftpd ..... install proftpd"
    echo "       --mariadb <mariadb version> ..... set mariadb version manually (default 10.3)"
    echo " Other options :"
    echo "       -h, --help, help ... displays this help information"
    echo ""
    return 0
}


##################################
# Arguments Parsing
##################################

### Read config
if [ -f ./config.inc ]; then
    {
        # shellcheck disable=SC1091
        . ./config.inc
    }
else
    {
        while [ "$#" -gt 0 ]; do
            case "$1" in
                -i | --interactive)
                    INTERACTIVE_SETUP="y"
                ;;
                --proftpd)
                    PROFTPD_INSTALL="y"
                ;;
                --clamav)
                    CLAMAV_INSTALL="y"
                ;;
                --monit)
                    MONIT_INSTALL="y"
                ;;
                --rkhunter)
                    RKHUNTER_INSTALL="y"
                ;;				
                --ee-cleanup)
                    EE_CLEANUP="y"
                ;;
                --travis)
                    TRAVIS_BUILD="y"
                ;;
                --extplorer)
                    WO_EXTPLORER_INSTALL="y"
                ;;
                -h|--help)
                    _help
                    exit 1
                ;;
                *) ;;
            esac
            shift
        done
    }
fi

##################################
# Welcome
##################################

echo ""
echo "Bem Vindo ao script Wo-instal-pack."
echo ""
echo " -------------------------------------------------------------------------
        WO-INSTALL-PACK - Script de Instalação do WordOps
 -------------------------------------------------------------------------
 FORKED         Este script é um fork do:
 GitHub:        https://github.com/VirtuBox/wo-nginx-setup
 Licença M.I.T
 -------------------------------------------------------------------------
 Version 1.0 - 04/2019
 -------------------------------------------------------------------------"

[ -d /etc/wo ] && {
    WO_PREVIOUS_INSTALL=1
}

##################################
# Menu
##################################



if [ "$INTERACTIVE_SETUP" = "y" ]; then

    echo ""
    if [ ! -d /etc/proftpd ]; then
        echo ""
        echo "#####################################"
        echo "FTP"
        echo "#####################################"
        echo "Voce quer instalar o proftpd ? (y/n)"
        while [[ $PROFTPD_INSTALL != "y" && $PROFTPD_INSTALL != "n" ]]; do
            read -p "Selecione a opção [y/n]: " PROFTPD_INSTALL
        done
    fi
    ########################################
    if [ -z "$(command -v clamscan)" ]; then
        echo ""
        echo "#####################################"
        echo "FTP"
        echo "#####################################"
        echo "Voce quer instalar o ClamAV ? (y/n)"
        while [[ $CLAMAV_INSTALL != "y" && $CLAMAV_INSTALL != "n" ]]; do
            read -p "Selecione a opção [y/n]: " CLAMAV_INSTALL
        done
	fi
    ######################################
    if [ -z "$(command -v monit)" ]; then
        echo ""
        echo "#####################################"
        echo "MONIT"
        echo "#####################################"
        echo "Voce quer instalar o Monit ? (y/n)"
        while [[ $MONIT_INSTALL != "y" && $MONIT_INSTALL != "n" ]]; do
            read -p "Selecione a opção [y/n]: " 	MONIT_INSTALL
        done
	fi
    ########################################
	if [ -z "$(command -v rkhunter)" ]; then
        echo ""
        echo "#####################################"
        echo "FTP"
        echo "#####################################"
        echo "Voce quer instalar o Rkhunter ? (y/n)"
        while [[ $RKHUNER_INSTALL != "y" && $RKHUNTER_INSTALL != "n" ]]; do
            read -p "Selecione a opção [y/n]: " 	RKHUNTER_INSTALL
        done
	fi	
		
fi

#adicionar swap
echo -e "${CGREEN}Adicionando memória swap...${CEND}"
{
    fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile; free -m

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Adição de memória swap${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Adição de memória swap${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###
###Pacotes do Sistemas Atualizados

echo -e "${CGREEN}Atualizando Pacotes do Sistemas...${CEND}"
[ -z "$TRAVIS_BUILD" ] && {

    apt-get update -y 
    apt-get upgrade -y
    apt-get dist-upgrade -y
    #apt-get autoremove -y --purge
    #apt-get autoclean -y

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Pacotes do Sistemas Atualizados${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Atualização dos Pacotes do Sistema${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###


###Instalação de Serviços Adicionais

 echo -e "${CGREEN}Instando Serviços Adicionais...${CEND}"
{
    apt-get install haveged jpegoptim optipng webp curl mutt git zip unzip fail2ban htop nload jq nmon tar gzip ntp ntpdate gnupg gnupg2 wget pigz tree ccze mycli screen tmux -y
    ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata

    # ntp time
    sudo systemctl enable ntp

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação de Serviços Adicionais${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação de Serviços Adicionais${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###


# increase history size
export HISTSIZE=10000

###Clonando repositorio
echo -e "${CGREEN}Clonando repositório...${CEND}"
{
    if [ ! -d $HOME/wo-install ]; then
        git clone https://github.com/juanpvh/wo-install.git $HOME/wo-install
    else
        git -C $HOME/wo-install pull origin master
    fi

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Repositório Clonado${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Clone do Repositório${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Instalando firewall - ufw
echo -e "${CGREEN}Instalando firewall - ufw...${CEND}"
{
    if [ ! -d /etc/ufw ]; then
        sudo apt-get install ufw -y
    fi

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Ufw instalado${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}instalação do ufw ${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Difinindo regras do firewall - ufw
echo -e "${CGREEN}Difinindo regras do firewall - ufw...${CEND}"
{
    sudo ufw logging low
    sudo ufw default allow outgoing
    sudo ufw default deny incoming

    # default ssh port
    sudo ufw allow 22

    # custom ssh port
    if [ "$CURRENT_SSH_PORT" != "22" ]; then
        sudo ufw allow "$CURRENT_SSH_PORT"
    fi

    # dns
    sudo ufw allow 53

    # nginx
    sudo ufw allow http
    sudo ufw allow https

    # ntp
    sudo ufw allow 123

    # dhcp client
    sudo ufw allow 68

    # dhcp ipv6 client
    sudo ufw allow 546

    # rsync
    sudo ufw allow 873

    # easyengine backend
    sudo ufw allow 22222

    # Netdata web interface
    sudo ufw allow 19999
    # Monit web interface
    sudo ufw allow 2812

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Regras do firewall adicionadas${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Adição das regras do firewall${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Otimizando Sysctl tweaks +  open_files limits
echo -e "${CGREEN}Otimizando Sysctl tweaks +  open_files limits...${CEND}"
{

        sudo cp -f $HOME/wo-install/etc/sysctl.d/60-ubuntu-nginx-web-server.conf /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
        sudo cp -f $HOME/wo-install/etc/security/limits.conf /etc/security/limits.conf

        # Redis transparent_hugepage
        echo never >/sys/kernel/mm/transparent_hugepage/enabled

    # disable ip forwarding if docker is not installed
    if [ ! -x /usr/bin/docker ]; then

        echo "" >>/etc/sysctl.d/60-ubuntu-nginx-web-server.conf
        {
            echo "# Disables packet forwarding"
            echo "net.ipv4.ip_forward = 0"
            echo "net.ipv4.conf.all.forwarding = 0"
            echo "net.ipv4.conf.default.forwarding = 0"
            echo "net.ipv6.conf.all.forwarding = 0"
            echo "net.ipv6.conf.default.forwarding = 0"
        } >>/etc/sysctl.d/60-ubuntu-nginx-web-server.conf

    fi

    # additional systcl configuration with network interface name
    # get network interface names like eth0, ens18 or eno1
    # for each interface found, add the following configuration to sysctl

    NET_INTERFACES_WAN=$(ip -4 route get 8.8.8.8 | grep -oP "dev [^[:space:]]+ " | cut -d ' ' -f 2)
    echo "" >>/etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    {
        echo "# do not autoconfigure IPv6 on $NET_INTERFACES_WAN"
        echo "net.ipv6.conf.$NET_INTERFACES_WAN.autoconf = 0"
        echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra = 0"
        echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra = 0"
        echo "net.ipv6.conf.$NET_INTERFACES_WAN.autoconf = 0"
        echo "net.ipv6.conf.$NET_INTERFACES_WAN.accept_ra_defrtr = 0"
    } >>/etc/sysctl.d/60-ubuntu-nginx-web-server.conf

    sudo sysctl -e -p /etc/sysctl.d/60-ubuntu-nginx-web-server.conf

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Otimização do Sysctl tweaks +  open_files limits${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Otimização do Sysctl tweaks +  open_files limits${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

################################################
###Instalação do WordOps
###############################################
echo -e "${CGREEN}Instalando WordOps...${CEND}"
{
    if [ -z "$WO_PREVIOUS_INSTALL" ]; then

        if [ ! -f $HOME/.gitconfig ]; then
            # define git username and email for non-interactive install
            USER=MarcosToniatto
            bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
        fi

        if [ ! -x /usr/local/bin/wo ]; then

            wget -qO wo wops.cc && sudo bash wo
            source /etc/bash_completion.d/wo_auto.rc
            rm -rf wo


        fi
    fi
} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação do WordOps${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação do WordOps${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Instalando Pack adicional do WordOps
echo -e "${CGREEN}Instalando pack do WordOps...${CEND}"
{

    /usr/local/bin/wo stack install --all --php73 --redis --admin --phpredisadmin --memcached --redis --utils
	apt-get install php7.2-intl php7.3-intl -y

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação da pack do WordOps${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação da pack do WordOps${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Otimizando a configuração do mariadb
echo -e "${CGREEN}Otimizando a configuração do mariadb...${CEND}"
{
    cp -f $HOME/wo-install/etc/mysql/my.cnf /etc/mysql/my.cnf
    # stop mysql service to apply new InnoDB log file size
    sudo service mysql stop
    # mv previous log file
    sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
    sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak
    # increase mariadb open_files_limit
    cp -f $HOME/wo-install/etc/systemd/system/mariadb.service.d/limits.conf /etc/systemd/system/mariadb.service.d/limits.conf
    # reload daemon
    systemctl daemon-reload
    # restart mysql
    service mysql start
    

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Otimização da configuração do mariaDB${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Otimização da configuração do mariaDB${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Configurando adicionais acesso www-data shell
echo -e "${CGREEN}Configurando acesso www-data shell...${CEND}"
{

    # change www-data shell
    usermod -s /bin/bash www-data

    if [ ! -f /etc/bash_completion.d/wp-completion.bash ]; then
        # download wp-cli bash-completion
        sudo wget -qO /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
 
  
        #Customize WordPress installation locale

        sudo cp -f $HOME/wo-install/etc/config.yml ~/.wp-cli/config.yml

    fi

    if [ ! -f /var/www/.profile ] && [ ! -f /var/www/.bashrc ]; then
        # create .profile & .bashrc for www-data user
        cp -f $HOME/wo-install/var/www/.profile /var/www/.profile
        cp -f $HOME/wo-install/var/www/.bashrc /var/www/.bashrc

        # set www-data as owner
        chown www-data:www-data /var/www/.profile
        chown www-data:www-data /var/www/.bashrc
    fi


} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Configurações adicionais acesso www-data shell${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Configurações adicionais acesso www-data shell${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###



###Compilando a Pilha Nginx-ee
echo -e "${CGREEN}Compilando a Pilha Nginx-ee...${CEND}"
{

    wget -O $HOME/nginx-build.sh vtb.cx/nginx-ee
    chmod +x $HOME/nginx-build.sh

    #executando a pilha
    $HOME/nginx-build.sh

        cp -f $HOME/wo-install/etc/nginx/conf.d/upstream.conf /etc/nginx/conf.d/upstream.conf
        cp -f $HOME/wo-install/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222
        cp -f $HOME/wo-install/etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini
        cp -f $HOME/wo-install/etc/php/7.3/fpm/php.ini /etc/php/7.3/fpm/php.ini

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Pilha Nginx-ee Instalada${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Pilha Nginx-ee${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Configuração adicional nginx, logrotate, fail2ban...
echo -e "${CGREEN}Configuração adicional nginx, logrotate, fail2ban...${CEND}"
{

    # optimized nginx.config
    #cp -f $HOME/wo-install/etc/nginx/nginx.conf /etc/nginx/nginx.conf

    # commit changes
    git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update conf.d configurations"


    # reduce nginx logs rotation
    sed -i 's/size 10M/weekly/' /etc/logrotate.d/nginx
    sed -i 's/rotate 52/rotate 4/' /etc/logrotate.d/nginx



    # commit changes
    git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update nginx.conf and setup cloudflare visitor real IP restore"


    VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)

    if [ -z "$VERIFY_NGINX_CONFIG" ]; then
        sudo service nginx reload
    else

        echo "Nginx configuration is not correct"

    fi

    # Add fail2ban configurations
    cp -rf $HOME/wo-install/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
    cp -rf $HOME/wo-install/etc/fail2ban/jail.d/* /etc/fail2ban/jail.d/

    fail2ban-client reload

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Configuração adicional nginx, logrotate, fail2ban${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Configuração adicional nginx, logrotate, fail2ban${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Instalando Clamav...
echo -e "${CGREEN}Instalando Clamav...${CEND}"
{
    if [ "$CLAMAV_INSTALL" = "y" ]; then

        if [ -z "$(command -v clamscan)" ]; then
            apt-get install clamav clamav-daemon -y
        fi

        /etc/init.d/clamav-freshclam stop
        freshclam
        /etc/init.d/clamav-freshclam start
    fi

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação do Clamav${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação do Clamav${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Instalando Monit...
echo -e "${CGREEN}Instalando Monit...${CEND}"
{
    
    if [ "$MONIT_INSTALL" = "y" ]; then


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
	        monit
	        monit reload
	
    fi	

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação do Monit${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação do Monit${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###


#if [ "$RKHUNTER_INSTALL" = "y" ]; then
#
#    ##################################
#    # Install Rkhunter
#    ##################################
#    echo "##########################################"
#    echo " Installing Rkhunter"
#    echo "##########################################"
#
#    if [ -z "$(command -v rkhunter)" ]; then
#	
#	apt-get install rkhunter -y
#
#	sed -i 's/UPDATE_MIRRORS=0/UPDATE_MIRRORS=1/' /etc/rkhunter.conf
#	sed -i 's/MIRRORS_MODE=1/UPDATE_MIRRORS=0/' /etc/rkhunter.conf
#	sed -i 's/WEB_CMD="\/bin\/false"/WEB_CMD=""/' /etc/rkhunter.conf
#
#	sed -i 's/CRON_DAILY_RUN=""/CRON_DAILY_RUN="true"/' /etc/default/rkhunter
#	sed -i 's/CRON_DB_UPDATE=""/CRON_DB_UPDATE="true"/' /etc/default/rkhunter
#	sed -i 's/APT_AUTOGEN="false"/APT_AUTOGEN="true"/' /etc/default/rkhunter
#	rkhunter -C
#	rkhunter --update
#	rkhunter --versioncheck
#	rkhunter --propupd
#	rkhunter --check --sk
#	
#    fi
#fi


###Instalando Nanorc...
#echo -e "${CGREEN}Instalando Nanorc...${CEND}"
{

    chmod +x $HOME/wo-install/var/www/nanorc.sh
    bash $HOME/wo-install/var/www/nanorc.sh

    wget -O mysqldump.sh virtubox.net/mysqldump
    chmod +x mysqldump.sh


} >> /tmp/registro.log 2>&1
#    if [ $? -eq 0 ]; then
#        echo -e "${CGREEN}Instalação no Nanorc${CEND}   [${CGREEN}OK${CEND}]"
#        echo ""
#    else
#        echo -e "${CRED}Instalação do Nanorcv${CEND}   [${CRED}FALHOU${CEND}]"
#        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
#    fi
###


###Instalando ProFTPd...
echo -e "${CGREEN}Instalando ProFTPd...${CEND}"
{
    if [ "$PROFTPD_INSTALL" = "y" ]; then

        apt-get install proftpd -y

        # secure proftpd and enable PassivePorts

        sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
        sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
        sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/ proftpd/proftpd.conf

        sudo service proftpd restart

        if [ -d /etc/ufw ]; then
            # ftp active port
            sudo ufw allow 21
            # ftp passive ports
            sudo ufw allow 49000:50000/tcp
        fi

        if [ -d /etc/fail2ban ]; then
            echo -e '\n[proftpd]\nenabled = true\n' >> /etc/fail2ban/jail.d/custom.conf
            fail2ban-client reload

        fi
    fi

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação do ProFTPd${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação do ProFTPd${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

###Instalando EXTPLORER...
echo -e "${CGREEN}Instalando EXTPLORER...${CEND}"
{
    if [ "$WO_EXTPLORER_INSTALL" = "y" ]; then

        if [ ! -d /var/www/22222/htdocs/files ]; then

            mkdir -p /var/www/22222/htdocs/files
            wget -qO /var/www/22222/htdocs/files/ex.zip https://extplorer.net/attachments/download/78/eXtplorer_2.1.12.zip
            cd /var/www/22222/htdocs/files || exit 1
            unzip ex.zip
            rm ex.zip
        fi

        cd /var/www/22222 || exit

    fi

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação do EXTPLORER${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação do EXTPLORER${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

####Instalando Mailhog e postfix
#echo -e "${CGREEN}Instalando Mailhog e postfix...${CEND}"
#{
#    wget -qO /var/www/22222/htdocs/mailhog.zip https://github.com/mailhog/MailHog/archive/master.zip
#    cd /var/www/22222/htdocs/ || exit 1
#    unzip mailhog.zip
#    rm -rf mailhog.zip
#    mv MailHog-master mailhog
#    chmod +x mailhog
#    cd || exit
#    chown -R www-data:www-data /var/www/22222/htdocs/
#	find /var/www/22222/htdocs/ -type f -exec chmod 644 {} +
#	find /var/www/22222/htdocs/ -type d -exec chmod 755 {} +
#
#cat >  /etc/systemd/system/mailhog.service << END
#[Unit]
#Description=MailHog service
#
#[Service]
#ExecStart=/usr/local/bin/mailhog
#
#[Install]
#WantedBy=multi-user.target
#END
#
#systemctl start mailhog
#systemctl enable mailhog
#
#
#debconf-set-selections <<< "postfix postfix/mailname string localhost"
#debconf-set-selections <<< "postfix postfix/main_mailer_type string 'smarthost'"
#apt-get install -y postfix
#
#} >> /tmp/registro.log 2>&1
#    if [ $? -eq 0 ]; then
#        echo -e "${CGREEN}Instalação Mailhog e postfix${CEND}   [${CGREEN}OK${CEND}]"
#        echo ""
#    else
#        echo -e "${CRED}Instalação Mailhog e postfix${CEND}   [${CRED}FALHOU${CEND}]"
#        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
#    fi
####

###Instalando Script de otimização de imagens...
echo -e "${CGREEN}Instalando script de otimização de imagens...${CEND}"
{

    sudo cp $HOME/wo-install/img-optimize-master/optimize.sh /usr/local/bin/img-optimize
    sudo cp $HOME/wo-install/img-optimize-master/crons/jpg-png-cron.sh /etc/cron.weekly/jpg-png-cron
    chmod +x /etc/cron.weekly/jpg-png-cron

    ##################################
    # create a database user called “netdata”
    ##################################

    #mysql -e "create user 'netdata'@'localhost';" > /dev/null 2>&1
    #mysql -e "GRANT USAGE on *.* to 'netdata'@'localhost'" > /dev/null 2>&1
    #mysql -e "FLUSH PRIVILEGES"


    ## optimize netdata resources usage
    #echo 1 >/sys/kernel/mm/ksm/run
    #echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

    ## disable email notifigrep -cions
    sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /opt/netdata/usr/lib/netdata/conf.d/health_alarm_notify.conf
    service netdata restart

} >> /tmp/registro.log 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Instalação Script de otimização de imagens${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}Instalação Script de otimização de imagens${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###


###Limpando Instalação...
echo -e "${CGREEN}Limpando php's versões anteriores...${CEND}"
{

    if [ "$EE_CLEANUP" = "y" ]; then

        apt-get -y autoremove php5.6-fpm php5.6-common --purge
        apt-get -y autoremove php7.0-fpm php7.0-common --purge
        apt-get -y autoremove php7.1-fpm php7.1-common --purge
        cd ~
    fi

} >> /tmp/registro.log 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Versões anteriores do php's removidos${CEND}   [${CGREEN}OK${CEND}]"
        echo ""
    else
        echo -e "${CRED}remoção dos antigos php's${CEND}   [${CRED}FALHOU${CEND}]"
        echo -e "${CRED}Verifique o arquivo /tmp/registro.log${CEND}"
    fi
###

ADDRESS=$(hostname -I | awk '{ print $1}')
echo " "
echo " Optimized Wordops was setup successfully! "
echo " Painel Principal: https://$ADDRESS:22222"
echo " Painel Netdata: https://$ADDRESS:22222/netdata"
echo " Painel Monit: https://$ADDRESS:22222/monit"
echo " "
