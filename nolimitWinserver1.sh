##### Users and Groups #####
ARRAYUSERS=( user1 user2 user3 user4 ) #  may end up changing from array
NEWPASS="password"
ROOTPASS="redhat"
FINDUSER="Zanti"
FINDDIR="/root/Misfits"
FINDFILES="/tmp/penal_colony /var/log/insectiods /etc/rat_sized /home/alien_demands"
FOUNDFILE1="penal_colony"
FOUNDFILE2="insectiods"
FOUNDFILE3="rat_sized"
FOUNDFILE4="alien_demands"
DOCROOT="/inner_limits"

cat > /home/vagrant/building.repo << EOF
[BaseOS]
name=BaseOS
baseurl=http://repo.eight.example.com/BaseOS
enabled=1
gpgcheck=0
[AppStream]
name=AppStream
baseurl=http://repo.eight.example.com/AppStream
enabled=1
gpgcheck=0
EOF
cp /home/vagrant/building.repo /etc/yum.repos.d/building.repo
yum install httpd nfs-utils words policycoreutils-python-utils-2.8-16.1.el8 -y &>/dev/null;
#Create VirtualHost for port 84 with DocumentRoot outside of /var/www/html
cat > /home/vagrant/servera.conf << EOF
listen 84
<VirtualHost *:84>
	ServerName	localhost
	DocumentRoot	$DOCROOT
	CustomLog	logs/localhost.access.log combined
	ErrorLog	logs/localhost.error.log
</VirtualHost>
<Directory ${DOCROOT}>
	Require all granted
</Directory>
EOF
mkdir -p /hung_hat/drifter;
chmod 777  /hung_hat/drifter;
chmod 777  /hung_hat/;
setsebool -P use_nfs_home_dirs 1;
cat >> /home/vagrant/exports << EOF
/hung_hat/drifter	*(rw,sync)
EOF
cp /home/vagrant/exports /etc/exports
systemctl enable nfs-server.service --now;
exportfs;
firewall-cmd --add-service=nfs;
firewall-cmd --add-service=nfs --permanent;
sed -i s/=permissive/=enforcing/g /etc/selinux/config;
setenforce 1;
cp /home/vagrant/servera.conf /etc/httpd/conf.d/server1.conf
mkdir /inner_limits
wget -O /inner_limits/index.html http://cloudjedi.org/starwars.html &>/dev/null
#Delete Repositories
rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
echo "creating user: ${FINDUSER}";
useradd $FINDUSER;
#Create files to be found $FINDFILES
echo "creating files for $FINDUSER"
touch $FINDFILES ;
#Change Ownership of those files to the $FINDOWNER
echo "changing ownership to ${FINDUSER} ";
chown $FINDUSER:$FINDUSER $FINDFILES ;
#Create $GREPFILE
#wget github.com/OpenCloudJedi/${GREPFILE}
#Remove firewall rule for Cockpit
firewall-cmd --zone=public --permanent --remove-service=cockpit;
