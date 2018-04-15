### Install Docker-ce

Script d'instalaltion de docker sur un Debian 9 vierge

Utilisation
```
wget -q -O - https://raw.githubusercontent.com/veka-server/docker-ce_install_debian/master/install.sh | bash
```

### Active API avec TLS

Dans l'exemple ci-dessous nous utiliserons le nom de domaine : machin.truc.com

Utilisation
```
wget -q -O - https://raw.githubusercontent.com/veka-server/docker-ce_install_debian/master/generate_certificates.sh | sh -s machin.truc.com
```
Editez le fichier de conf
```
nano /lib/systemd/system/docker.service
```
Modifier la ligne 
```
ExecStart=/usr/bin/dockerd -H =fd:// --tlsverify --tlscacert=/root/.docker/ca.pem --tlscert=/root/.docker/server-cert.pem --tlskey=/root/.docker/server-key.pem -H=0.0.0.0:2375
```
Recharger le systeme de service
```
systemctl daemon-reload
```
Redemarrer docker
```
service docker restart
```
Tester  l'API
```
curl https://machin.truc.com:2375/images/json --cert ~/.docker/cert.pem --key ~/.docker/key.pem --cacert ~/.docker/ca.pem
```
Si le retour est un tableau vide la config est terminée.

### Active API sans TLS

![#f03c15](https://placehold.it/15/f03c15/000000?text=+) DANGEREUX NE PAS FAIRE SI ACCESSIBLE DEPUIS INTERNET `#f03c15`


Editez le fichier de conf
```
nano /lib/systemd/system/docker.service
```
Modifier la ligne 
```
ExecStart=/usr/bin/dockerd -H =fd:// -H=tcp://0.0.0.0:2375
```
Recharger le systeme de service
```
systemctl daemon-reload
```
Redemarrer docker
```
service docker restart
```
Tester  l'API
```
curl http://localhost:2375/images/json
```
Si le retour est un tableau vide la config est terminée.

