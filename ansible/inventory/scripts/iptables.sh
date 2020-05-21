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
