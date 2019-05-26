#/bin/bash
#wget https://manager.servicodigital.info/install-mwc.sh && chmod +x install-mwc.sh && ./install-mwc.sh
VERDE='\e[0;32m'
NC='\e[0m' 

DIR=$(ls -1L /var/www -I22222 -Ihtml) 
 
#Loop para instalar o plugin em todos os diretorios encontrados
for dominio in ${DIR[@]};
 	
	cd /var/www/$dominio/htdocs/wp-content/plugins/
	wp --allow-root plugin delete mainwp-child
	chown -R www-data:www-data /var/www/$dominio/htdocs/
	find /var/www/$dominio/htdocs/ -type f -exec chmod 644 {} +
	find /var/www/$dominio/htdocs/ -type d -exec chmod 755 {} +
	echo -e "${VERDE}Plugin Deletado em ${dominio} ${NC}"

done
#
cd ~ 
rm -rf dellplugin.sh

