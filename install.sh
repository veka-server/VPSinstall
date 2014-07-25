#!/bin/bash
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#  installation des system de base 
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------

passRoot="000000"
passVeka="000000"
passMacwarrior="000000"
passwordRootSql="000000"
passMumble="000000"
passSuperUser_Mumbe="00000"0

# reset des logs
echo '' > /tmp/main
echo '' > /tmp/log
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------

create_buffer(){
  # Try to use SHM, then $TMPDIR, then /tmp
  if [ -d "/dev/shm" ]; then
    BUFFER_DIR="/dev/shm"
  elif [ -z $TMPDIR ]; then
    BUFFER_DIR=$TMPDIR
  else
    BUFFER_DIR="/tmp"
  fi

  [[ "$1" != "" ]] &&  buffername=$1 || buffername="bashsimplecurses"

  # Try to use mktemp before using the unsafe method
  if [ -x `which mktemp` ]; then
    mktemp --tmpdir=${BUFFER_DIR} ${buffername}.XXXXXXXXXX
  else
    echo "${BUFFER_DIR}/bashsimplecurses."$RANDOM
  fi
}

#Usefull variables
LASTCOLS=0
BUFFER=`create_buffer`
POSX=0
POSY=0
LASTWINPOS=0

#call on SIGINT and SIGKILL
#it removes buffer before to stop
on_kill(){
    echo "Exiting"
    rm -rf $BUFFER

    on_kill_user

    exit 0
}
trap on_kill SIGINT SIGTERM


#initialize terminal
term_init(){
    POSX=0
    POSY=0
    tput clear >> $BUFFER
}


#change line
_nl(){
    POSY=$((POSY+1))
    tput cup $POSY $POSX >> $BUFFER
    #echo 
}


move_up(){
    set_position $POSX 0
}

col_right(){
    left=$((LASTCOLS+POSX))
    set_position $left $LASTWINPOS
}

#put display coordinates
set_position(){
    POSX=$1
    POSY=$2
}

#initialize chars to use
_TL="\033(0l\033(B"
_TR="\033(0k\033(B"
_BL="\033(0m\033(B"
_BR="\033(0j\033(B"
_SEPL="\033(0t\033(B"
_SEPR="\033(0u\033(B"
_VLINE="\033(0x\033(B"
_HLINE="\033(0q\033(B"
init_chars(){    
    if [[ "$ASCIIMODE" != "" ]]; then
        if [[ "$ASCIIMODE" == "ascii" ]]; then
            _TL="+"
            _TR="+"
            _BL="+"
            _BR="+"
            _SEPL="+"
            _SEPR="+"
            _VLINE="|"
            _HLINE="-"
        fi
    fi
}

#Append a windo on POSX,POSY
window(){
    LASTWINPOS=$POSY
    title=$1
    color=$2      
    tput cup $POSY $POSX 
    cols=$(tput cols)
    cols=$((cols))
    if [[ "$3" != "" ]]; then
        cols=$3
        if [ $(echo $3 | grep "%") ];then
            cols=$(tput cols)
            cols=$((cols))
            w=$(echo $3 | sed 's/%//')
            cols=$((w*cols/100))
        fi
    fi
    len=$(echo "$1" | echo $(($(wc -c)-1)))
    left=$(((cols/2) - (len/2) -1))

    #draw up line
    clean_line
    echo -ne $_TL
    for i in `seq 3 $cols`; do echo -ne $_HLINE; done
    echo -ne $_TR
    #next line, draw title
    _nl

    tput sc
    clean_line
    echo -ne $_VLINE
    tput cuf $left
    #set title color
    case $color in
        green)
            echo -n -e "\E[01;32m"
            ;;
        red)
            echo -n -e "\E[01;31m"
            ;;
        blue)
            echo -n -e "\E[01;34m"
            ;;
        grey|*)
            echo -n -e "\E[01;37m"
            ;;
    esac
    
    
    echo $title
    tput rc
    tput cuf $((cols-1))
    echo -ne $_VLINE
    echo -n -e "\e[00m"
    _nl
    #then draw bottom line for title
    addsep
    
    LASTCOLS=$cols

}

#append a separator, new line
addsep (){
    clean_line
    echo -ne $_SEPL
    for i in `seq 3 $cols`; do echo -ne $_HLINE; done
    echo -ne $_SEPR
    _nl
}


#clean the current line
clean_line(){
    tput sc
    #tput el
    tput rc
    
}


#add text on current window
append_file(){
    [[ "$1" != "" ]] && align="left" || align=$1
    while read l;do
        l=`echo $l | sed 's/____SPACES____/ /g'`
        _append "$l" $align
    done < "$1"
}
append(){
    text=$(echo -e $1 | fold -w $((LASTCOLS-2)) -s)
    rbuffer=`create_buffer bashsimplecursesfilebuffer`
    echo  -e "$text" > $rbuffer
    while read a; do
        _append "$a" $2
    done < $rbuffer
    rm -f $rbuffer
}
_append(){
    clean_line
    tput sc
    echo -ne $_VLINE
    len=$(echo "$1" | wc -c )
    len=$((len-1))
    left=$((LASTCOLS/2 - len/2 -1))
    
    [[ "$2" == "left" ]] && left=0

    tput cuf $left
    echo -e "$1"
    tput rc
    tput cuf $((LASTCOLS-1))
    echo -ne $_VLINE
    _nl
}

#add separated values on current window
append_tabbed(){
    [[ $2 == "" ]] && echo "append_tabbed: Second argument needed" >&2 && exit 1
    [[ "$3" != "" ]] && delim=$3 || delim=":"
    clean_line
    tput sc
    echo -ne $_VLINE
    len=$(echo "$1" | wc -c )
    len=$((len-1))
    left=$((LASTCOLS/$2)) 
    for i in `seq 0 $(($2))`; do
        tput rc
        tput cuf $((left*i+1))
        echo "`echo $1 | cut -f$((i+1)) -d"$delim"`" 
    done
    tput rc
    tput cuf $((LASTCOLS-1))
    echo -ne $_VLINE
    _nl
}

#append a command output
append_command(){
    buff=`create_buffer command`
    echo -e "`$1`" | sed 's/ /____SPACES____/g' > $buff 2>&1
    append_file $buff "left"
    rm -f $buff
}

#close the window display
endwin(){
    clean_line
    echo -ne $_BL
    for i in `seq 3 $LASTCOLS`; do echo -ne $_HLINE; done
    echo -ne $_BR
    _nl
}

#refresh display
refresh (){
    cat $BUFFER
    echo "" > $BUFFER
}



#main loop called
main_loop (){
    term_init
    init_chars
    [[ "$1" == "" ]] && time=1 || time=$1
    while [[ 1 ]];do
        tput cup 0 0 >> $BUFFER
        tput il $(tput lines) >>$BUFFER
        main >> $BUFFER 
        tput cup $(tput lines) $(tput cols) >> $BUFFER 
        refresh
        sleep $time
        POSX=0
        POSY=0
    done
}

#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------

if [ $USER != root ]; then
echo "Vous devez etre en root pour utiliser le script"
exit 1;
fi 

on_kill_user()
{
  #configuration de phpmyadmin
  dpkg-reconfigure -plow phpmyadmin

  dpkg-reconfigure mumble-server
  sed -i 's/database=/#database=/' /etc/mumble-server.ini
  sed -i 's/icesecretwrite=/#icesecretwrite=/' /etc/mumble-server.ini
  sed -i "1i\database=mumble" /etc/mumble-server.ini
  sed -i "1i\dbDriver=QMYSQL" /etc/mumble-server.ini
  sed -i "1i\dbUsername=mumble" /etc/mumble-server.ini
  sed -i "1i\dbPassword=$passMumble" /etc/mumble-server.ini
  sed -i "1i\dbHost=localhost" /etc/mumble-server.ini
  sed -i "1i\dbPrefix=murmur_" /etc/mumble-server.ini

    echo 'create database mumble ;' > /tmp/tmp.sql
    echo "grant all on mumble.* to mumble@'localhost' identified by '$passMumble' ;" >> /tmp/tmp.sql
    mysql -u root -p$passwordRootSql < /tmp/tmp.sql
    rm /tmp/tmp.sql

  evalLog '/etc/init.d/mumble-server restart'

#  configuration de postfix
#  dpkg-reconfigure postfix

#  dpkg-reconfigure courier-base
#  dpkg-reconfigure courier-imap

}

evalMain()
{
   eval "$1  &>> /tmp/main"
}

evalLog()
{
   eval "$1 &>> /tmp/log"
}

update()
{
   evalMain 'echo ":: Mise a jour du serveur"'
   evalLog 'apt-get -y update'
   evalLog 'apt-get -y upgrade'
}

root()
{
   evalMain 'echo ":: Modification du mot de passe root"'
   evalLog 'echo  -e "'$1'\n'$1'\n" | passwd root'

}


makeUser()
{
   # creation de l'utilisateur
   evalMain 'echo ":: Creation du compte de '$1' "'
   evalLog 'useradd -m '$1
   evalLog 'echo -e "'$2'\n'$2'\n" | passwd '$1
}

install_apache()
{
   evalMain 'echo ":: Installation apache" '
   evalLog 'apt-get -y install apache2 apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert'

   # activation des réecriture d'URL
   evalLog 'a2enmod rewrite'

   evalLog '/etc/init.d/apache2 start'

}


install_php()
{
   evalMain 'echo ":: Installation de PHP "'
   
   evalLog 'apt-get -y install libapache2-mod-php5 php5 php5-common php5-curl php5-dev php5-gd php5-idn php-pear php5-imagick php5-imap php5-json php5-mcrypt php5-memcache php5-mhash php5-ming php5-mysql php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-apc'

   echo "
   <VirtualHost *:80>
      ServerAdmin veka61@laposte.net
      ServerName 82.196.11.194
      DocumentRoot /srv/hello
      <Directory />
              Options FollowSymLinks
              AllowOverride None
      </Directory>
      <Directory /srv/hello>
              Options Indexes FollowSymLinks MultiViews
              AllowOverride None
              Order allow,deny
              allow from all
      </Directory>
   </VirtualHost>" > /etc/apache2/sites-available/001-hello

   echo "
   ServerName 127.0.0.1" >> /etc/apache2/apache2.conf

   evalLog 'mkdir /srv/hello'

   echo "<?php echo 'hello world' ?>" > /srv/hello/index.php

   evalLog 'chmod -R 777 /srv/hello'

   evalLog 'a2dissite 000-default'

   evalLog 'a2ensite 001-hello'

   # redemarrage d'apache pour prendre en compte les modifications
   evalLog '/etc/init.d/apache2 restart'

}

install_nodejs()
{
   evalMain 'echo ":: Installation de NodeJs" '

    evalLog 'apt-get -y install python g++ make git-core'
    evalLog 'echo "Telechargement des sources de nodejs"'
    evalLog 'git clone https://github.com/joyent/node.git -q '
    cd node
    evalLog 'echo "Configure"'
    evalLog './configure --openssl-libpath=/usr/lib/ssl'
    evalLog 'echo "Compilation"'
    evalLog 'make'
    evalLog 'echo "Installation"'
    evalLog 'make install'
    cd
    # Configure seems not to find libssl by default so we give it an explicit pointer.
    # Optionally: you can isolate node by adding --prefix=/opt/node
    #./configure --openssl-libpath=/usr/lib/ssl

    evalLog 'echo "Nettoyage"'
    evalLog 'rm -r node*'
}

install_fail2ban()
{
  evalMain 'echo ":: Installation de fail2ban" '
  evalLog 'apt-get -y install fail2ban'
}

install_mysql()
{
  evalMain 'echo ":: Installation de mysql" '
  export DEBIAN_FRONTEND=noninteractive
  evalLog 'sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db'
  evalLog 'apt-get -y install mariadb-server'
  evalLog 'mysqladmin -u root password $passwordRootSql'
}

install_phpmyadmin()
{
  evalMain 'echo ":: Installation de phpmyadmin" '
  evalLog 'apt-get -y install phpmyadmin'
}

install_htop()
{
  evalMain 'echo ":: Installation de htop" '
  evalLog 'apt-get -y install htop'
}

install_postfix()
{
  evalMain 'echo ":: Installation de postfix" '
  evalLog 'apt-get -y install postfix'
}

install_bind()
{
  evalMain 'echo ":: Installation de bind" '
  evalLog 'apt-get -y install bind9'
}

install_courier()
{
  evalMain 'echo ":: Installation de courier" '
  evalLog 'apt-get -y install courier-authdaemon courier-base courier-imap courier-maildrop courier-pop courier-pop-ssl courier-imap-ssl'
}

install_mumble()
{
  evalMain 'echo ":: Installation de mumble" '
  evalLog 'apt-get -y install lzma bzip2 mumble-server git'
  cd /srv/hello/
  evalLog 'git clone https://github.com/veka-server/murmurRegister.git'
}

script()
{

   # un accées root est requis
   root $passRoot

   update

   makeUser "veka" $passVeka
   makeUser "macwarrior" $passMacwarrior

   install_apache

   install_php

   install_mysql

   install_phpmyadmin

   install_postfix

   install_courier

   install_fail2ban

   install_bind

   install_htop

   install_mumble

   install_nodejs

  evalMain 'echo ":: Fin du script" '

}

#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------


#creer la fenetre principal
main(){
    window "Script d'installation" "green"
    append_command "tail -n 10 /tmp/main"
    addsep
    append_command "tail -n 8 /tmp/log"
    endwin
}
 
# lancer le script principal
eval "script" &

#then ask the standard loop
main_loop 1

