#/bin/bash
#wget https://manager.servicodigital.info/install-mwc.sh && chmod +x install-mwc.sh && ./install-mwc.sh
VERDE='\e[0;32m'
NC='\e[0m'
PLUGINWP=$(wordpress-seo mainwp-child )
DIR=$(ls -1L /var/www -I22222 -Ihtml) 
 
#Loop para instalar o plugin em todos os diretorios encontrados
for dominio in ${DIR[@]}; do
 	
	cd /var/www/$dominio/htdocs/wp-content/plugins/
	wp plugin install mainwp-child --activate --allow-root --path=/var/www/
chown -R www-data:www-data /var/www/
find /var/www/ -type f -exec chmod 644 {} +
find /var/www/ -type d -exec chmod 755 {} +
	echo -e "${VERDE}Plugin Instalado em ${dominio} ${NC}"
	 
done
#
cd ~ 
rm -rf installplugin.sh

