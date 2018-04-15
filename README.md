Install Docker-ce
==========

Script d'instalaltion de docker sur un Debian 9 vierge

Utilisation
```
wget -q -O - https://raw.githubusercontent.com/veka-server/docker-ce_install_debian/master/install.sh | bash
```

Active API sans TLS
==========

Editez le fichier de conf
```
nano /lib/systemd/system/docker.service
```
Modifier la ligne 
```
ExecStart=/usr/bin/docker daemon -H=fd:// -H=tcp://0.0.0.0:2375
```
Recharger le systeme de service
```
systemctl daemon-reload
```
Redemarrer docker
```
sudo service docker restart
```
Tester  l'API
```
curl http://localhost:2375/images/json
```

