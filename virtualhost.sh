#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
rootdir=$3
owner=$(who am i | awk '{print $1}')
email='webmaster@localhost'
sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
userDir='/var/www/'
sitesAvailabledomain=$sitesAvailable$domain.conf

### don't modify from here unless you know what you are doing ####

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
		if [ -e $sitesAvailabledomain ]; then
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
		if ! echo "
		<VirtualHost *:80>
			ServerAdmin $email
			ServerName $domain
			ServerAlias $domain
			DocumentRoot $userDir$rootdir
			<Directory />
				AllowOverride All
			</Directory>
			<Directory $userDir$rootdir>
				Options Indexes FollowSymLinks MultiViews
				AllowOverride all
				Require all granted
			</Directory>
			ErrorLog /var/log/apache2/$domain-error.log
			LogLevel error
			CustomLog /var/log/apache2/$domain-access.log combined
		</VirtualHost>" > $sitesAvailabledomain
		then
			echo -e $"Ocorreu um erro ao criar $domain arquivo"
			exit;
		else
			echo -e $"\nNew Virtual Host Criado\n"
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
			chown -R $(whoami):$(whoami) $userDir$rootdir
		else
			chown -R $owner:$owner $userDir$rootdir
		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Pronto! \nSeu VirtualHost foi criado \nSeu novo host é : http://$domain \nE está localizado em  $userDir$rootdir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"Este domínio não exite."
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $userDir$rootdir ]; then
			echo -e $"Delete diretório root ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
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
