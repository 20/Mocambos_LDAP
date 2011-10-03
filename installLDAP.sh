# Some colors for better world
export WHITE="\e[1;37m";export LGRAY="\e[0;37m";export GRAY="\e[1;30m";export BLACK="\e[0;30m";export RED="\e[0;31m"
export LRED="\e[1;31m";export GREEN="\e[0;32m";export LGREEN="\e[1;32m";export BROWN="\e[0;33m";export YELLOW="\e[1;33m"
export BLUE="\e[0;34m";export LBLUE="\e[1;34m";export PURPLE="\e[0;35m";export PINK="\e[1;35m";export CYAN="\e[0;36m"
export LCYAN="\e[1;36m";export EC="\e[0m"

# Colored echo's
echoc(){
    echo -e "$1 $2 $EC"
}

echoc $GREEN "This script is not for general use (but you can customize :) ). Used/tested in Ubuntu 10.04 LTS."

echoc $RED "Installing an OpenLDAP Server for Mocambos Network"
echoc $RED "Warning.. this will erase all previous LDAP databases and related config files"
read -p "Are you sure? " -n 1
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echoc $RED " ... "
    echoc $RED "Ok.. nothing done! Quitting ... "
    exit 1
fi

# Removing old OpenLdap stuff
echoc $RED " ... "
echoc $RED "Removing old OpenLdap stuff ..."
sudo apt-get remove --purge slapd ldap-utils -y
sleep 2

remove=(/etc/ldap /var/lib/ldap)
for x in "${remove[@]}"
do
    echoc $RED "removing $x"
    sudo rm -rf $x
done

# Install OpenLdap packages
echoc $RED "Installing OpenLdap packages ..."
sudo apt-get install slapd ldap-utils -y

# Add default base schemas
echoc $RED "Adding base schemas..."
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif

mkdir /tmp/ldifo
slaptest -f config/schema_convert.conf -F /tmp/ldifo/
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/ldifo/cn\=config/cn\=schema/cn\=\{6\}dyngroup.ldif
rm -rf /tmp/ldifo

# Add mocambos backend schema
echoc $RED "Adding backend schema:"
echoc $RED "Adding backend.mocambos.net.ldif ..." 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f config/backend.mocambos.net.ldif

# Add mocambos frontend schema 
echoc $RED "Adding fontend schema:"
echoc $RED "Adding frontend.mocambos.net.ldif ..." 
sudo ldapadd -x -D cn=admin,dc=mocambos,dc=net -W -f config/frontend.mocambos.net.ldif

echoc $RED "Do you want to start replication for this server?"
echoc $RED "No (n), Provider (p), Consumer (c), N-way_Multimaster (m)"

read -n 1 serverType
case $serverType in
    [nN])
	echoc $RED "Ok.. enjoy your new ldap server!";;
    [pP])
	echoc $RED "Configuring the server as a PROVIDER..."
	echoc $GREEN "Remember to add these lines to /etc/apparmor.d/usr.sbin.slapd :"
	echoc $LGREEN "  /var/lib/ldap/accesslog/ r,"
	echoc $LGREEN "  /var/lib/ldap/accesslog/** rwk,"
	sudo -u openldap mkdir /var/lib/ldap/accesslog
	sudo -u openldap cp /var/lib/ldap/DB_CONFIG /var/lib/ldap/accesslog/
	sleep 2
	sudo ldapadd -Y EXTERNAL -H ldapi:/// -f config/provider_sync.ldif
	sudo /etc/init.d/slapd restart
	;;
    [cC])
	echoc $RED "Configuring the server as a CONSUMEER..."
	echoc $GREEN "Remember to add these lines to /etc/apparmor.d/usr.sbin.slapd :"
	echoc $LGREEN "  /var/lib/ldap/accesslog/ r,"
	echoc $LGREEN "  /var/lib/ldap/accesslog/** rwk,"
	sudo -u openldap mkdir /var/lib/ldap/accesslog
	sudo -u openldap cp /var/lib/ldap/DB_CONFIG /var/lib/ldap/accesslog/
	sleep 2
	sudo ldapadd -Y EXTERNAL -H ldapi:/// -f config/consumer_sync.ldif
	sudo /etc/init.d/slapd restart
	;;
    [mM])
	echoc $RED "Configuring the server as a N-WAY_MULTIMASTER..."
	echoc $GREEN "Remember to add these lines to /etc/apparmor.d/usr.sbin.slapd :"
	echoc $LGREEN "  /var/lib/ldap/accesslog/ r,"
	echoc $LGREEN "  /var/lib/ldap/accesslog/** rwk,"
	sudo -u openldap mkdir /var/lib/ldap/accesslog
	sudo -u openldap cp /var/lib/ldap/DB_CONFIG /var/lib/ldap/accesslog/
	sleep 2
	echoc $RED "Is this the main server (1) or the local (2)?"
	read -n 1 serverNumber
	sudo ldapadd -Y EXTERNAL -H ldapi:/// -f config/n-way-multimaster$serverNumber.ldif
	sudo /etc/init.d/slapd restart
	;;
esac


