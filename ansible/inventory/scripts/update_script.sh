#!/bin/bash
TEXT_RESET='\e[0m'
TEXT_YELLOW='\e[0;33m'
TEXT_GREEN='\e[0;32m'
TEXT_RED='\e[31m'

INTRO="
▄• ▄▌ ▄▄▄··▄▄▄▄   ▄▄▄·▄▄▄▄▄▄▄▄ .     ▄▄▄· ▄▄▄·  ▄▄· ▄ •▄  ▄▄▄·  ▄▄ • ▄▄▄ ..▄▄ · 
█▪██▌▐█ ▄███▪ ██ ▐█ ▀█•██  ▀▄.▀·    ▐█ ▄█▐█ ▀█ ▐█ ▌▪█▌▄▌▪▐█ ▀█ ▐█ ▀ ▪▀▄.▀·▐█ ▀. 
█▌▐█▌ ██▀·▐█· ▐█▌▄█▀▀█ ▐█.▪▐▀▀▪▄     ██▀·▄█▀▀█ ██ ▄▄▐▀▀▄·▄█▀▀█ ▄█ ▀█▄▐▀▀▪▄▄▀▀▀█▄
▐█▄█▌▐█▪·•██. ██ ▐█ ▪▐▌▐█▌·▐█▄▄▌    ▐█▪·•▐█ ▪▐▌▐███▌▐█.█▌▐█ ▪▐▌▐█▄▪▐█▐█▄▄▌▐█▄▪▐█
 ▀▀▀ .▀   ▀▀▀▀▀•  ▀  ▀ ▀▀▀  ▀▀▀     .▀    ▀  ▀ ·▀▀▀ ·▀  ▀ ▀  ▀ ·▀▀▀▀  ▀▀▀  ▀▀▀▀ 
 "

#SET UP INTRODUCTION ASCII
echo $TEXT_YELLOW
echo "$INTRO"
echo  $TEXT_RESET

echo $TEXT_GREEN
echo "........................downloading last packages........................"
DOWNLOAD=`sudo apt-get -y update`
GETTING=$(sudo apt-get -y upgrade)
GETTING2=$GETTING
check1=` echo "$GETTING" | grep "upgraded" | cut -c 1`
check2=` echo "$GETTING" | grep "upgraded" | cut -f 2 -d',' | cut -c 2`

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
	echo $GETTING2
	echo $TEXT_RESET
fi
