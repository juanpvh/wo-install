#!/usr/bin/env bash
#
# SCRIPT DE MIGRAÇÃO DE SITES DO EAASYENGINE PARA EASYENGINE OU PARA WORDOPS.
#
# Version: 1.0.0
# Fork: https://github.com/ahmadawais/BR-CLI
# Author: Juan Maia.
# Author URI: http://github.com/juanpvh.
#
# Props & Credits: andreafabrizi, wpbullet (Mike Adreasen)

# wget https://manager.servicodigital.info/wo-mr-cli.sh && chmod +x wo-mr-cli.sh

# Colors.
#
# colors from tput
# http://stackoverflow.com/a/20983251/950111
# Usage:
# echo "${redb}red text ${gb}green text${r}"
bb=`tput setab 0` #set background black
bf=`tput setaf 0` #set foreground black
gb=`tput setab 2` # set background green
gf=`tput setab 2` # set background green
blb=`tput setab 4` # set background blue
blf=`tput setaf 4` # set foreground blue
rb=`tput setab 1` # set background red
rf=`tput setaf 1` # set foreground red
wb=`tput setab 7` # set background white
wf=`tput setaf 7` # set foreground white
r=`tput sgr0`     # r to defaults

clear
cd ~


echo "—"
echo "${gb}${bf} WO-UP ⚡️  ${r}"

echo "—"
# CHECANDO OS PARAMENTROS DE CONFIGURAÇÃO.
for i in "$@" ; do
	# MIGRANDO TUDO.
	if [[ $i == "--backup" || $i == "-b" ]] ; then
		BACKUP_ALL="yes"
	fi

done

# DIRETORIOS DEFINIDO PARA OS BACKUPS.
BACKUPPATH=~/BACKUPS

# CRIA O DIRETORIO SE ELE NÃO EXISTIR.
mkdir -p $BACKUPPATH

# DIRETORIOS RAIZ DE INSTALAÇÃO DO SITES WORDPRESS.
SITESTORE=/var/www


# CRIANDO ARRAY DA BASE DO SITES E IGNORANDO AS DIRETORIOS 22222 E HTML.
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)


#.# MIGRANDO TODOS OS SITES.
#
#   MIGRAÇÃO DE TODOS OS SITES.
#
#   @VERSÃO 1.0.0
if [[ "$BACKUP_ALL" == "yes" ]]; then

	# INICIADO LOOP
	for SITE in ${SITELIST[@]}; do
		echo "——————————————————————————————————"
		echo "⚡️  Migrando site: $SITE..."
		echo "——————————————————————————————————"
		
		# ENTRANDO NO DIRETORIOS DOS SITES WORDPRESS.
		cd $SITESTORE/$SITE/

		# CHECANDO E/OU CRINANDO O DIRETORIO DE BACKUPS SE EXISTES.
		if [ ! -e $BACKUPPATH/$SITE ]; then
			mkdir -p $BACKUPPATH/$SITE
		fi

		echo "——————————————————————————————————"
		echo "⏲  Criando arquivo de backup do: $SITE..."
		echo "——————————————————————————————————"

		# ZIPANDO BACKUP.
		tar -czf $BACKUPPATH/$SITE/$SITE.tar.gz . 
		

		echo "——————————————————————————————————"
		echo "⏲  Criando o Backup do banco de dados: $SITE..."
		echo "——————————————————————————————————"

		# BACKUP DO BANCO DE DADOS.
		wp db repair --path=$SITESTORE/$SITE/htdocs/ --allow-root
		wp db optimize --path=$SITESTORE/$SITE/htdocs/ --allow-root
		wp db export $BACKUPPATH/$SITE/$SITE.sql --allow-root --path=$SITESTORE/$SITE/htdocs
		tar -czf $BACKUPPATH/$SITE/$SITE.sql.gz $BACKUPPATH/$SITE/$SITE.sql
		rm $BACKUPPATH/$SITE/$SITE.sql
		wp plugin update --all --path=$SITESTORE/$SITE/htdocs/ --allow-root
	
		echo "——————————————————————————————————"
		echo "🔥  $SITE Backup Complete!"
		echo "——————————————————————————————————"
		
	    # FIXANDO PERMISSÕES.
	    chown -R www-data:www-data $SITESTORE
	    find $SITESTORE -type f -exec chmod 644 {} +
	    find $SITESTORE -type d -exec chmod 755 {} +
		

	done
	
		echo "——————————————————————————————————"
		echo "🔥  Backup e atualização Completo!"
		echo "——————————————————————————————————"

	# DELETA TODOS OS BACKUPS LOCAIS.

fi



wp db repair --path=/var/www/painelmt.servicodigital.info/htdocs/ --allow-root
wp db optimize --path=/var/www/painelmt.servicodigital.info/htdocs/ --allow-root