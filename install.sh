#!/bin/bash

echoVERT()
{
    echo -e "\033[32m $1 \033[0m "
}

echoVERT ':: Mise a jour du serveur'
apt-get -y update
apt-get -y upgrade

echoVERT ':: Ajout du depot'
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

echoVERT ':: Installation de Docker-CE'
apt-get -y update
apt-get -y install docker-ce

echoVERT ':: Fin du script'
