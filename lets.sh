#/bin/bash
#wget https://manager.servicodigital.info/lets.sh && chmod +x lets.sh && ./lets.sh
#atucaliza o php para versao 7.0 e o certificado ssl
VERDE='\e[0;32m'
NC='\e[0m' 

SITELIST=$(ls -1L /var/www -I22222 -Ihtml)

 
#Loop para instalar o plugin em todos os diretorios encontrados
for dominio in ${SITELIST[@]}; do
 
  pingsite=$(ping -c2 $dominio)
 
  if [[ $? = 0 ]] && [[ -d "/var/www/$dominio" ]]; then

  if [ -z /usr/local/bin/wo ]; then
  	
	wo site update $dominio --le=renew

  else

  ee site update $dominio --le=renew
  
  fi
	
  fi

done

rm -rf /$HOME/lets.sh