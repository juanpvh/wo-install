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
echo "${gb}${bf} WO-MR-CLI ⚡️  ${r}"
echo "${wb}${bf} Version 1.0.0 ${r}"
echo "${wb}${bf} SCRIPT DE MIGRAÇÃO DE SITES DO EAASYENGINE PARA EASYENGINE OU PARA WORDOPS.${r}"
echo "—"
# CHECANDO OS PARAMENTROS DE CONFIGURAÇÃO.
for i in "$@" ; do
	# MIGRANDO TUDO.
	if [[ $i == "--migration" || $i == "-m" ]] ; then
		MIGRATION_ALL="yes"
	fi

	# RESTAURANDO TUDO.
	if [[ $i == "--restore" || $i == "-r" ]] ; then
		RESTORE_ALL="yes"
	fi

	# RESTAURANDO UM SITE APENAS.
	if [[ $i == "--sigle" || $i == "-s" ]] ; then
		SIGLE_MIGRATION="yes"
	fi

	# Help.
	if [[ $i == "-h" || $i == "help" ]] ; then
		echo "——————————————————————————————————"
		echo "⚡️ Usage: [ -m | --migration ] [ -r | --restore ] and [ -h | help ]"
		echo "⚡️  - [ -h | help ] Usage help."
		echo "⚡️  - [ -s | --sigle ] migra um site para outro servidor com rsync"
		echo "⚡️  - [ -m | --migration ] migra todos os sites para outro servidor com rsync"
		echo "⚡️  - [ -r | --restore ] Restaura todos os sites no /var/www/ com seus bancos de dados."
		echo "——————————————————————————————————"
	fi
done

# DIRETORIOS DEFINIDO PARA OS BACKUPS.
BACKUPPATH=~/backupmigration

# CRIA O DIRETORIO SE ELE NÃO EXISTIR.
mkdir -p $BACKUPPATH

# DIRETORIOS RAIZ DE INSTALAÇÃO DO SITES WORDPRESS.
SITESTORE=/var/www


# CRIANDO ARRAY DA BASE DO SITES E IGNORANDO AS DIRETORIOS 22222 E HTML.
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITELISTREST=$(ls -1L $BACKUPPATH/)

#.# MIGRANDO UM SITE.
#
#   MIGRANDO UM SITE POR VEZ.
#
#   @VERSAO 1.0.0
if [[ "$SIGLE_MIGRATION" == "yes" ]]; then
	echo "——————————————————————————————————"
	echo -ne "👉  Insira o NOME DO SITE único para fazer backup. [E.g. site.tld]: " ; read SITE_NAME
	echo "——————————————————————————————————"

	echo "——————————————————————————————————"
	echo "⚡️  Site a ser migrado: $SITE_NAME..."
	echo "——————————————————————————————————"
	

	# ENTRANDO NO DIRETORIO DO SITE.
	cd $SITESTORE/$SITE_NAME/

	# CHECANDO E/OU CRINANDO O DIRETORIO DE BACKUPS SE EXISTES.
	if [ ! -e $BACKUPPATH/$SITE_NAME ]; then
		mkdir -p $BACKUPPATH/$SITE_NAME
	fi

	echo "——————————————————————————————————"
	echo "⏲  Criando arquivo de backup do: $SITE_NAME..."
	echo "——————————————————————————————————"

	# # ZIPANDO BACKUP.
	tar -czf $BACKUPPATH/$SITE_NAME/$SITE_NAME.tar.gz .
	
	echo "——————————————————————————————————"
	echo "⏲  Criando o Backup do banco de dados: $SITE_NAME..."
	echo "——————————————————————————————————"

	# Back up the WordPress database.
	wp db repair --path=$SITESTORE/$SITE_NAME/htdocs/ --allow-root
	wp db optimize --path=$SITESTORE/$SITE_NAME/htdocs/ --allow-root
	wp db export $BACKUPPATH/$SITE_NAME/$SITE_NAME.sql --allow-root --path=$SITESTORE/$SITE_NAME/htdocs
	tar -czf $BACKUPPATH/$SITE_NAME/$SITE_NAME.sql.gz $BACKUPPATH/$SITE_NAME/$SITE_NAME.sql
	rm $BACKUPPATH/$SITE_NAME/$SITE_NAME.sql


	echo "——————————————————————————————————"
	echo "⏲  Enviando o Backup para o novo SERVIDOR..."
	echo "——————————————————————————————————"

	echo "—"
	echo -ne "${gb}${bf}Digite o IP do servidor quer ira receber o backup:${r} " ; read  IP_ANDRESS
    echo "—"

	echo "——————————————————————————————————"
	echo "⏲  Novo SERVIDOR:$IP_ANDRESS..."
	echo "——————————————————————————————————"

		# ENVIANDO OS BACKUPS COM RSYNC.
		rsync -azh --progress $BACKUPPATH/ root@$IP_ANDRESS:$BACKUPPATH/

	echo "——————————————————————————————————"
	echo "🔥  $SITE_NAME Backup Complete!"
	echo "——————————————————————————————————"


	# DELETA TODOS OS BACKUPS LOCAIS.
	rm -rf $BACKUPPATH/$SITE_NAME

	# FIXANDO PERMISSÕES.
	chown -R www-data:www-data $SITESTORE/$SITE_NAME/htdocs/
	find $SITESTORE/$SITE_NAME/htdocs/ -type f -exec chmod 644 {} +
	find $SITESTORE/$SITE_NAME/htdocs/ -type d -exec chmod 755 {} +
fi



#.# MIGRANDO TODOS OS SITES.
#
#   MIGRAÇÃO DE TODOS OS SITES.
#
#   @VERSÃO 1.0.0
if [[ "$MIGRATION_ALL" == "yes" ]]; then

		echo "—"
		echo -ne "${gb}${bf}Digite o IP do servidor quer ira receber o backup:${r} " ; read  IP_ANDRESS
		echo "—"

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

		echo "——————————————————————————————————"
		echo "⏲  Enviando o Backup para o novo SERVIDOR:$IP_ANDRESS..."
		echo "——————————————————————————————————"

		# ENVIANDO OS BACKUPS COM RSYNC.
		rsync -azh --progress $BACKUPPATH/ root@$IP_ANDRESS:$BACKUPPATH/
	
		echo "——————————————————————————————————"
		echo "🔥  $SITE Backup Complete!"
		echo "——————————————————————————————————"
		
	   # FIXANDO PERMISSÕES.
	   chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
	   find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
	   find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

	done

	# DELETA TODOS OS BACKUPS LOCAIS.
	rm -rf $BACKUPPATH/*

fi

#.# RESTAURANDO TUDO.
#
#   RESTAURANDO TODOS OS SITES.
#
#   @VERSAO 1.0.0
if [[ "$RESTORE_ALL" == "yes" ]]; then

	# INCIANDO O LOOP.
	for SITE in ${SITELISTREST[@]}; do

		if [ ! -e $BACKUPPATH/$SITE ]; then
		echo "$SITE Não existe!"
		fi

	#CRIANDO SITE NOVO A SER RESTAURADO DE BACKUP.

		echo "——————————————————————————————————"
		echo "⚡️  Criando site: $SITE..."
		echo "——————————————————————————————————"

		wo site create $SITE --wp


		echo "——————————————————————————————————"
		echo "⚡️  Restaurando site: $SITE..."
		echo "——————————————————————————————————"
		

		cd $BACKUPPATH/$SITE


		# REMOVENDO A DIRETORIO HTDOCS.
		rm -rf $SITESTORE/$SITE/htdocs

		echo "——————————————————————————————————"
		echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
		echo "——————————————————————————————————"

		mkdir -p $BACKUPPATH/$SITE/files
		mkdir -p $BACKUPPATH/$SITE/db

		echo "——————————————————————————————————"
		echo "⏲  Extraindo o backup..."
		echo "——————————————————————————————————"

		# Un tar the backup,
		# -C To extract an archive to a directory different from the current.
		tar -xzf $BACKUPPATH/$SITE/$SITE.tar.gz -C $BACKUPPATH/$SITE/files/
		rm -rf $BACKUPPATH/$SITE/files/{backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"

		# REMOVENDO ARQUIVO DO BACKUP.
		#rm -rfv $BACKUPPATH/$SITE/$SITE.tar.gz

		tar -xzf $BACKUPPATH/$SITE/$SITE.sql.gz -C $BACKUPPATH/$SITE/db/ --strip-components=3
		echo "DB extraido"

		# REMOVENDO ARQUIVO DO BD DE BACKUP .
		#rm -rfv $BACKUPPATH/$SITE/$SITE.sql.gz

		echo "——————————————————————————————————"
		echo "⏲  Restaurando arquivos..."
		echo "——————————————————————————————————"

		# ADCIONANDO BACKUP.
		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/files/* $SITESTORE/$SITE
		
		#wp plugin delete --path=$SITESTORE/$SITE/htdocs/ {nginx-helper,w3-total-cache} --allow-root

		echo "——————————————————————————————————"
		echo "⏲  Restaurando banco de dados..."
		echo "——————————————————————————————————"

		# Resetando banco de dados .
	
		wp db reset --yes --allow-root --path=$SITESTORE/$SITE/htdocs/ 

		# IMPORTADNO BANCO DE DADOS PARA NOVO SITE.
		wp db import $BACKUPPATH/$SITE/db/$SITE.sql --path=$SITESTORE/$SITE/htdocs/ --allow-root #--dbuser=$DB_USERX --dbpass=$DB_PASSX

		echo "——————————————————————————————————"
		echo "⏲  Fixando permissões..."
		echo "——————————————————————————————————"

		sudo chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
		sudo find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
		sudo find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

		# DELETANDO ARAUIVOS DE BACKUPS.
		#rm -rfv $BACKUPPATH/$SITE

		echo "——————————————————————————————————"
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"
	done
	
	
fi


#.# If no parameter is added.
if [ $# -eq 0 ]; then
	echo "——————————————————————————————————"
	echo "❌ Nenhum argumento válido!"
	echo "——————————————————————————————————"
	echo "Usage: wo-mr-cli [ -m |--migration ], [ -r | --restore ], [ -s | --sigle ] and [ -h | help ]"
	echo "——————————————————————————————————"
	exit 1
fi
