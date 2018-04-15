#!/bin/bash

echoVERT()
{
    echo -e "\033[31m $1 \033[0m "
}

echoVERT 'Mise a jour du serveur'
evalLog 'apt-get -y update'
evalLog 'apt-get -y upgrade'

echoVERT 'Ajout du depot'
evalLog 'apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common'     
evalLog 'curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"'

echoVERT 'Installation de Docker-CE'
evalLog 'apt-get -y update'
evalLog 'apt-get -y install docker-ce'

evalMain 'echo ":: Fin du script" '
