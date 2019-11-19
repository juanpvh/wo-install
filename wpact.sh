#/bin/bash

VERDE='\e[0;32m'
NC='\e[0m' 
DIR=$(ls -1L /var/www -I22222 -Ihtml) 
 
#Loop para instalar o plugin em todos os diretorios encontrados
for dominio in ${DIR[@]}; do
 	
	cd /var/www/$dominio/htdocs/
	wp plugin deactivate --all --allow-root
    sleep 3
    wo clean --all
    wp plugin activate --all --allow-root
	chown -R www-data:www-data /var/www/$dominio/htdocs/
	find /var/www/$dominio/htdocs/ -type f -exec chmod 644 {} +
	find /var/www/$dominio/htdocs/ -type d -exec chmod 755 {} +
	echo -e "${VERDE}FEITO = ${dominio} ${NC}"
	 
done

