# 42_roger-skyline-1

Aim : initiation to system and network administration part 2.

**1 - MAJ**
sudo apt-get update && sudo apt-get upgrade
Install utils ; sudo apt-get install sudo vim portsentry fail2ban apache2 mailutils -y

**2 - SUDO**
vi /etc/sudoers
rajouté sa ligne avec son pseudo dans user privilege

**3 - IP STATIC NETMASK 30**
vi /etc/network/interfaces

Auto enp0s3
	iface enp0s3 inet static
	address 10.12.30.30 ( chosir son adresse)
	netmask 255.255.255.252 (calcul ss masque reseau)
gateway 10.11.254.254 (par défaut)

	sudo service networking restart

	Ifconfig ou ip addr

**4 - SSH**

Se faire un pont (bridge connexion sur VBOX)

	sudo vi /etc/ssh/sshd_config

	Decommenter le port le changer port < 1023 reservé
	registred port >1024 et < 49151
	Dynamic port > 49152 et <65535

	Now on peut se connecter en ssh avec l’adresse choisi et le port
	ssh saouas@10.12.30.30 -p 50683


	Sur Mac OS: ajout de la key dans .ssh/authorized_keys
- Ssh-keygen -t rasa (creation d’une clef)
	- Ssh-copy-id -I id_rsa.pub ssh saouas@10.12.30.30 -p 50683
	Apres ca on peut retirer le
	PasswordAuthentification no
	PermitRootLogin no
	Authorizedkeysfile : renseigner le champs
	PubkeyAuthentification yes

	Sudo service sshd restart

**5 - FIREWALL**

	Source : https://doc.ubuntu-fr.org/iptables
	Source : http://ipset.netfilter.org/iptables-extensions.man.html

	apt-get install iptables-persistent
	Iptables-persistent
	Regle non conserver entre 2 redémarrages
	sudo vim /etc/network/if-pre-up.d/iptables

	Script :

#!/bin/bash

	iptables-restore < /etc/iptables.test.rules

# Flush iptables (nettoyage)
	iptables -F
	iptables -X
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X

# On drop tout le trafic entrant. (drop = bloquer)
	iptables -P INPUT DROP

# On drop tout le trafic sortant.
	iptables -P OUTPUT DROP

# On drop le forward
	iptables -P FORWARD DROP

# Permettre a une connexion ouverte de recevoir du trafic en entré (celle deja etablies ).
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permettre l'ouverture du port 50683 80 et 443 depuis la carte reseau enp0s3 depuis le protocol tcp
# port serveur web 80 et 443 et port de connexion ssh 50683
	iptables -A INPUT -p tcp -i enp0s3 --dport 50683 -j ACCEPT
	iptables -A INPUT -p tcp -i enp0s3 --dport 80 -j ACCEPT
	iptables -A INPUT -p tcp -i enp0s3 --dport 443 -j ACCEPT

# Permettre a  une connexion ouverte de recevoir du trafic en sortie.
	iptables -A OUTPUT -m conntrack ! --ctstate INVALID -j ACCEPT

# On accepte la boucle locale en entrée.
	iptables -I INPUT -i lo -j ACCEPT

# On log les paquets en entrée.
	iptables -A INPUT -j LOG

# On log les paquets forward.
	iptables -A FORWARD -j LOG

#Maitrise de charge : limiter le nombre de connexions maximum (10) autoriser en simultane par une ip
	iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 --connlimit-mask 20 -j DROP

	exit 0

	Reboot
	Checker ses règles : sudo iptables -L

	**6 - DOS**

	Créez un fichier de log pour votre serveur Apache pour savoir qui accede au serveur depuis quel ip on aura besoin pour filtrer les attaques
	sudo touch /var/log/apache2/server.log

	Le packet fail2ban intègre des protections contre les attaques courantes. Il suffit de les activer en créant un fichier de configuration local. Cela permet de ne pas modifier directement les jails par défaut de jail.conf.

	New fichier jail.local :


#Protection against SSH ATTACK
#3 requests to ssh connexion then ban for 10 mins
	[sshd]
	enabled = true
	port    = 50683
	logpath = %(sshd_log)s
	backend = %(sshd_backend)s
	maxretry = 3
	bantime = 600

#Protection against DOS ATTACK
#300 requests in 2min --> ban for 10min
	[http-get-dos]
	enabled = true
	port = http,https
	filter = http-get-dos
	logpath = /var/log/apache2/server.log
	maxretry = 300
	findtime = 300
	bantime = 600
	action = iptables[name=HTTP, port=http, protocol=tcp]


	Source : https://doc.ubuntu-fr.org/fail2ban

	Creer le filtre http-get-dos inexistent :

	sudo vi /etc/fail2ban/filter.d/http-get-dos.conf

#Fail2Ban configuration file
# Author: http://www.go2linux.org

	[Definition]
# Option: failregex
# Note: This regex will match any GET entry in your logs, so basically all valid and not valid entries are a match.
# You should set up in the jail.conf file, the maxretry and findtime carefully in order to avoid false positives.

	failregex = ^<HOST>.*\"GET

# Option: ignoreregex
# Notes.: regex to ignore. If this regex matches, the line is ignored.
# Values: TEXT
#

	ignoreregex =


	Source : https://blog.nicolargo.com/2012/02/proteger-son-serveur-en-utilisant-fail2ban.html

	Restart du service : sudo systemctl restart fail2ban.service

	sudo Iptables -L affiche 2 règles f2b désormais

	Source : https://fr-wiki.ikoula.com/fr/Se_prot%C3%A9ger_contre_le_scan_de_ports_avec_portsentry

	Utilisation du mode avancé Modifier : sudo vi /etc/default/portsentry afin d'avoir :

	TCP_MODE="atcp"
	UDP_MODE="audp"

	Sudo vi /etc/portsentry/portsentry.conf
	Ligne 135 , 136 éditer le fichier  BLOCK_UDP et BLOCK_TCP à 1 comme ci-dessous :

	BLOCK_UDP="1"
	BLOCK_TCP="1"

	Nous allons opter pour un blocage des personnes malveillantes par le biais d'iptables.

	Ligne 209 de commenter cette ligne :
	KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"
	Commenter toute les autres commencent part KILL_ROUTE

	Verifier avec cette commande : cat portsentry.conf | grep KILL_ROUTE | grep -v "#"

	Source : https://fr-wiki.ikoula.com/fr/Se_prot%C3%A9ger_contre_le_scan_de_ports_avec_portsentry

	**7 - Disable Service**

	List all services available : sudo systemctl list-unit-files

	Sudo systemctl disable <services to disable>

	For example thos one are useless :
	sudo systemctl disable console-setup.service
	sudo systemctl disable keyboard-setup.service
	sudo systemctl disable apt-daily.timer
	sudo systemctl disable apt-daily-upgrade.timer
	sudo systemctl disable syslog.service

	sudo apt-get upgrade && sudo apt-get update
	 sudo vim /etc/crontab et éditer le fichier comme suit:

	0 4	* * 1	root	/home/saouas/update_script.sh  >> /var/log/update_script.log
	@reboot		root	/home/saouas/update_script.sh  >> /var/log/update_script.log

	Script bash :

#!/bin/bash
	TEXT_RESET='\e[0m'
	TEXT_YELLOW='\e[0;33m'
	TEXT_GREEN='\e[0;32m'
	TEXT_RED='\e[31m'

	INTRO="
	�~V~D�~@� �~V~D�~V~L �~V~D�~V~D�~V~D··�~V~D�~V~D�~V~D�~V~D   �~V~D�~V~D�~V~D·�~V~D�~V~D�~V~D�~V~D�~V~D�~V~D�~V~D�~V~D .     �~V~D�~V~D�~V~D· �~V~D�~V~D�~V~D·  �~V~D�~V~D· �~V~D �~@��~V~D  �~V~D�~V~D�~V~D·  �~V~D�~V~D �~@� �~V~D�~V~D�~V~D ..�~V~D�~V~D ·
	�~V~H�~V��~V~H�~V~H�~V~L�~V~P�~V~H �~V~D�~V~H�~V~H�~V~H�~V� �~V~H�~V~H �~V~P�~V~H �~V~@�~V~H�~@��~V~H�~V~H  �~V~@�~V~D.�~V~@·    �~V~P�~V~H �~V~D�~V~H�~V~P�~V~H �~V~@�~V~H �~V~P�~V~H �~V~L�~V��~V~H�~V~L�~V~D�~V~L�~V��~V~P�~V~H �~V~@�~V~H �~V~P�~V~H �~V~@ �~V��~V~@�~V~D.�~V~@·�~V~P�~V~H �~V~@.
	�~V~H�~V~L�~V~P�~V~H�~V~L �~V~H�~V~H�~V~@·�~V~P�~V~H· �~V~P�~V~H�~V~L�~V~D�~V~H�~V~@�~V~@�~V~H �~V~P�~V~H.�~V��~V~P�~V~@�~V~@�~V��~V~D     �~V~H�~V~H�~V~@·�~V~D�~V~H�~V~@�~V~@�~V~H �~V~H�~V~H �~V~D�~V~D�~V~P�~V~@�~V~@�~V~D·�~V~D�~V~H�~V~@�~V~@�~V~H �~V~D�~V~H �~V~@�~V~H�~V~D�~V~P�~V~@�~V~@�~V��~V~D�~VV
	~D�~V~@�~V~@�~V~@�~V~H�~V~D
	�~V~P�~V~H�~V~D�~V~H�~V~L�~V~P�~V~H�~V�·�~@��~V~H�~V~H. �~V~H�~V~H �~V~P�~V~H �~V��~V~P�~V~L�~V~P�~V~H�~V~L·�~V~P�~V~H�~V~D�~V~D�~V~L    �~V~P�~V~H�~V�·�~@��~V~P�~V~H �~V��~V~P�~V~L�~V~P�~V~H�~V~H�~V~H�~V~L�~V~P�~V~H.�~V~H�~V~L�~V~P�~V~H �~V��~V~P�~V~L�~V~P�~V~H�~V~D�~V��~V~P�~V~H�~V~P�~V~H�~V~D�~V~D�~~
	V~L�~V~P�~V~H�~V~D�~V��~V~P�~V~H
	�~V~@�~V~@�~V~@ .�~V~@   �~V~@�~V~@�~V~@�~V~@�~V~@�~@�  �~V~@  �~V~@ �~V~@�~V~@�~V~@  �~V~@�~V~@�~V~@     .�~V~@    �~V~@  �~V~@ ·�~V~@�~V~@�~V~@ ·�~V~@  �~V~@ �~V~@  �~V~@ ·�~V~@�~V~@�~V~@�~V~@  �~V~@�~V~@�~V~@  �~V~@�~V~@�~V~@�~V~@
	"
	DOWNLOAD=`sudo apt-get update`
	GETTING=`sudo apt-get upgrade`
	for GETTING in "$@"
	do
$(GETTING)
	done

	check1=` echo "$GETTING" | grep "upgraded" | cut -c 1`
	check2=` echo "$GETTING" | grep "upgraded" | cut -f 2 -d',' | cut -c 2`

#SET UP INTRODUCTION ASCII
	echo $TEXT_YELLOW
	echo "$INTRO"
	echo  $TEXT_RESET

	echo $TEXT_GREEN
	echo "........................downloading last packages........................"
	for DOWNLOAD in "$@"
	do
($DOWLOAD)
	echo  $TEXT_RESET
	done

	if [ "$check1" = "0" ] && [ "$check2" = "0" ]
	then
	echo $TEXT_GREEN
	echo ">>>>>>>>>>>>>>AUCUNE MISE A JOUR NECESSAIRE POUR VOTRE MACHINE<<<<<<<<<<<<<<<"
	echo  $TEXT_RESET
	else
	echo $TEXT_RED
	echo ">>>>>>>>>>>>>DES PACKETS N'ETAIENT PAS A JOUR... MAINTENANT TOUT EST A JOUR , details bellow!!!<<<<<<<<<<<<<<<<"
	echo $TEXT_RESET
	echo $TEXT_GREEN
	echo $GETTING
	echo $TEXT_RESET
	fi
	~
	~
	~
	~
	~
	~
	~

	**8 - Surveillance script**

	On copie son crontab :
	Sudo cp /etc/crontab /home/USER/tmp

	On crée une template pour le mail :
	Sudo vi /home/USER/email.txt

	On crée un alias pour pouvoir lire les mails
	Dans sudo vi/etc/aliases

	Ajouter:  “root: salimaouas@gmail.com”

	Source : https://doc.fedora-fr.org/wiki/Rediriger_les_mails_root_d%27un_serveur
	Source : http://www.linuxpedia.fr/doku.php/etc/crontab

	**9 - PARTIE WEB**
	Generer une clé ssl pour 1 an au format x509 en stockant certificat et clé dans deux fichiers separers :

	sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/roger-skyline.com.key -out /etc/ssl/certs/roger-skyline.com.crt

	Modifier le fichier de configuration ssl de apache:

	Sudo vi /etc/apache2/sites-available/default-ssl.conf

	Renseigner le certificat et la clé ssl :
	SSLEngine on

	SSLCertificateFile	/etc/ssl/certs/apache-selfsigned.crt
	SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

	Modifier le fichier de config du virtual host de apaches :
	Sudo vi /etc/apache2/sites-available/000-default.conf

	sudo apachectl configtest
	sudo a2enmod ssl
	sudo a2ensite default-ssl

	Ensuite on relance les serveurs apache :
	systemctl reload apache2

	Source : https://codebeamer.com/cb/wiki/2187378
	Source : https://www.sslmarket.fr/ssl/help-la-difference-entre-certificats
	Source : https://www.linuxtricks.fr/wiki/creer-un-certificat-auto-signe-et-le-renseigner-dans-apache2-ou-nginx

	**10 - DEPLOIEMENT ANSIBLE**

	installation ansible :
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
	sudo apt-get update
	sudo apt-get install ansible

	create inventory :

	hosts :

	[server]
	server1 ansible_host=10.12.30.30 ansible_port=50683  ansible_user=saouas

	learn yaml language :)

	creates some playsbooks , have fun :)))

source : https://docs.ansible.com/ansible/

