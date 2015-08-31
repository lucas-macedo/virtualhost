Gerador de VirtualHost no Ubuntu/Debian
===========

Bash Script para permitir criar ou excluir VirtualHost do apache/nginx  no Ubuntu/Debian de maneira rápida.

## Instalação ##

1. Download do script
2. Setar permissões:

        $ chmod +x /path/to/virtualhost.sh

3. Opicional: Se você quer deixar o script como globa, você tem que copiar o arquivo para /usr/local/bin o diretório.
        $ sudo cp /path/to/virtualhost.sh /usr/local/bin/virtualhost

### Instalação Global ###

        $ cd /usr/local/bin
        $ wget -O virtualhost https://raw.githubusercontent.com/RoverWire/virtualhost/master/virtualhost.sh
        $ chmod +x virtualhost
        $ wget -O virtualhost-nginx https://raw.githubusercontent.com/RoverWire/virtualhost/master/virtualhost-nginx.sh
        $ chmod +x virtualhost-nginx

## Usando ##

Comandos básicos:

    $ sudo sh /path/to/virtualhost.sh [create | delete] [dominio] [opicional caminho_pasta]

    Para instalação global:

    $ sudo virtualhost [create | delete] [dominio] [opicional caminho_pasta]


### Exemlos ###

Criar um novo VirtualHost:

    $ sudo virtualhost create site.dev

Criar um novo VirtualHost e definir a pasta:

    $ sudo virtualhost create outrosite.dev minha_pasta

Para deletar um VirtualHost: 

    $ sudo virtualhost delete mysite.dev

Para deletar um VirtualHost com em uma pasta definida:

    $ sudo virtualhost delete outrosite.dev minha_pasta

### Localizações

Para Apache:

		$ sudo cp /path/to/locale/<language>/virtualhost.mo /usr/share/locale/<language>/LC_MESSAGES/

Para NGINX:

		$ sudo cp /path/to/locale/<language>/virtualhost-nginx.mo /usr/share/locale/<language>/LC_MESSAGES/
