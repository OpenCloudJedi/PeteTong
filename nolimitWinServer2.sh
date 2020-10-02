##### VG & LV #####
EXISTINGVGNAME="Plot"
EXISTINGPESIZE="8M"
EXISTINGLVNAME="Thickens"
EXISTINGLVSIZE="256M"
EXISTINGFSTYPE="xfs"
EXISTINGMOUNTPOINT="/TwistAtEnd"
EXISTINGFSLOW="650"
EXISTINGFSHIGH="750"
SWAPPART1SIZE="+256M"
SWAPBYTELOW="500000"
SWAPBYTEHIGH="540000"

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
sudo cp /home/vagrant/building.repo /etc/yum.repos.d/building.repo
sudo yum install nfs-utils -y
sudo rm -f /etc/yum.repos.d/building.repo
sudo head -c 32 /dev/urandom | sudo passwd --stdin root;
sudo head -c 32 /dev/urandom | sudo passwd --stdin vagrant;
sudo useradd -M -d /hung_hat/drifter drifter;
echo 'fdisk -u  /dev/sdb <<EOF' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '1' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '2' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '3' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'w' >> /home/vagrant/part;
echo 'EOF' >> /home/vagrant/part;
sudo chmod +x /home/vagrant/part;
sudo bash /home/vagrant/part;
sudo partprobe;
#Create existing swap
sudo mkswap /dev/sdb1 &>/dev/null;
#Create VG and set PE size
sudo pvcreate /dev/sdb2 /dev/sdb3 &>/dev/null
sudo vgcreate -s $EXISTINGPESIZE $EXISTINGVGNAME /dev/sdb2 /dev/sdb3 &>/dev/null;
#Create LV
sudo lvcreate -n $EXISTINGLVNAME -L $EXISTINGLVSIZE $EXISTINGVGNAME &>/dev/null;
#Create FileSystem
sudo mkfs -t $EXISTINGFSTYPE /dev/${EXISTINGVGNAME}/${EXISTINGLVNAME} &>/dev/null;
#Add to /etc/fstab
echo '/dev/$EXISTINGVGNAME/$EXISTINGLVNAME $EXISTINGMOUNTPOINT $EXISTINGFSTYPE defaults 0 0' | sudo tee -a /etc/fstab;
echo '/dev/sdb1 swap swap defaults 0 0' | sudo tee -a /etc/fstab;
sudo mkdir ${EXISTINGMOUNTPOINT}
sudo swapon -a;
sudo mount -a;
#Change performance profile from default to anything else...
sudo tuned-adm profile throughput-performance;
#Install autofs, but do not enable
sudo yum remove vim -y &>/dev/null;
#Extend grub timeout
#Fix grub
sudo sed -i s/TIMEOUT=1/TIMEOUT=20/g /etc/default/grub ;
sudo grub2-mkconfig -o /boot/grub2/grub.cfg;"
