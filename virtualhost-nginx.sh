#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
rootdir=$3
owner=$(who am i | awk '{print $1}')
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
userDir='/var/www/'

if [ "$(whoami)" != 'root' ]; then
	echo $"Você não tem permissão para executar $0 como non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"Você precisa definir uma ação (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Defina um domínio, ex: projeto.dev"
	read domain
done

if [ "$rootdir" == "" ]; then
	rootdir=${domain//./}
fi

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailable$domain ]; then
			echo -e $"O domínio ja existe.\nTente outro"
			exit;
		fi

		### check if directory exists or not
		if ! [ -d $userDir$rootdir ]; then
			### create the directory
			mkdir $userDir$rootdir
			### give permission to root dir
			chmod 755 $userDir$rootdir
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $userDir$rootdir/phpinfo.php
				then
				echo $"ERROR: Não é possível de escrever no arquivo $userDir/$rootdir/phpinfo.php. Veja as permissões"
					exit;
			else
				echo $"Adicionado conteúdo $userDir$rootdir/phpinfo.php"
			fi
		fi

		### create virtual host rules file
		if ! echo "server {
			listen   80;
			root $userDir$rootdir;
			index index.php index.html index.htm;
			server_name $domain;

			# serve static files directly
			location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
				access_log off;
				expires max;
			}

			# removes trailing slashes (prevents SEO duplicate content issues)
			if (!-d \$request_filename) {
				rewrite ^/(.+)/\$ /\$1 permanent;
			}

			# unless the request is for a valid file (image, js, css, etc.), send to bootstrap
			if (!-e \$request_filename) {
				rewrite ^/(.*)\$ /index.php?/\$1 last;
				break;
			}

			# removes trailing 'index' from all controllers
			if (\$request_uri ~* index/?\$) {
				rewrite ^/(.*)/index/?\$ /\$1 permanent;
			}

			# catch all
			error_page 404 /index.php;

			location ~ \.php$ {
				fastcgi_split_path_info ^(.+\.php)(/.+)\$;
				fastcgi_pass 127.0.0.1:9000;
				fastcgi_index index.php;
				include fastcgi_params;
			}

			location ~ /\.ht {
				deny all;
			}

		}" > $sitesAvailable$domain
		then
			echo -e $"Ocorreu um erro ao criar $domain arquivo"
			exit;
		else
			echo -e $"Host adicionado no arquivo /etc/hosts  \n"
		fi

		### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
			then
			echo $"ERROR: Sem permissões para acessar /etc/hosts"
				exit;
		else
			echo -e $"Host adicionado no arquivo /etc/hosts  \n"
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):www-data $userDir$rootdir
		else
			chown -R $owner:www-data $userDir$rootdir
		fi

		### enable website
		ln -s $sitesAvailable$domain $sitesEnable$domain

		### restart Nginx
		service nginx restart

		### show the finished message
		echo -e $"Pronto! \nSeu VirtualHost foi criado \nSeu novo host é : http://$domain \nE está localizado em  $userDir$rootdir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailable$domain ]; then
			echo -e $"Este domínio não exite."
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			rm $sitesEnable$domain

			### restart Nginx
			service nginx restart

			### Delete virtual host rules files
			rm $sitesAvailable$domain
		fi

		### check if directory exists or not
		if [ -d $userDir$rootdir ]; then
			echo -e $"Delete diretório root ? (y/n)"
			read deldir

			if [ "$deldir" == 's' -o "$deldir" == 'S' ]; then
				### Delete the directory
				rm -rf $userDir$rootdir
				echo -e $"Diretório deletado"
			else
				echo -e $"Diretório mantido"
			fi
		else
			echo -e $"Diretório não encontrado."
		fi

		### show the finished message
		echo -e $"Pronto!\nVocê removeu seu VirtualHost $domain"
		exit 0;
fi
