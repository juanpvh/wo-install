# WO Install
Script para instalação do WordOps com o script wo-nginx-setup de Virtubox mais alguns utilitários para configurar seu servidor.

Script em construção:

Itens que serão integrados ao script

[github Issues](https://github.com/juanpvh/wo-install/issues/1)

vamos la!

# define git username and email for non-interactive install
    
```
bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
```

### Instalando:

```
wget https://raw.githubusercontent.com/juanpvh/wo-install/master/wo-install-pack.sh && chmod +x wo-install-pack.sh && clear && ./wo-install-pack.sh
```

### Outros:

```
wget https://raw.githubusercontent.com/juanpvh/wo-install/master/wo-mr-cli.sh && chmod +x wo-mr-cli.sh && clear && ./wo-mr-cli.sh
```

```
wget https://raw.githubusercontent.com/juanpvh/wo-install/master/lets.sh && chmod +x lets && clear && ./lets.sh
```



