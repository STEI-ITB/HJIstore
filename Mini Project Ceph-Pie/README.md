# Mini Ceph Pie
## Introduction
This project was adapted from an existing project. You can check the original one in: https://github.com/GitHippo/Ceph-Pi.
I made some modification:
- This project use manual method installation. Installation process includes inital monitor and OSD. When I try ceph-deploy, I encountered some problems related to repository. I can't find some packages, for example: ceph-osd.
- This project uses mimic version

## Tools and Material Needed
- Raspberry Pi 3x
- MicroSD 16 GB 3x
- Ethernet cable 3x for cluster, 1x for public network.
- Switch
- Flashdisk 32GB 6x. Each Rasp-Pi will handle up to 2 OSD.
- Laptop (optional, for configuration. I use SSH to configure the Rasp-Pi through my laptop)

## Topology
<br>My laptop
<br>  |
<br>  |
<br>Internet
<br>  |
<br>  |
<br>Switch 
<br>	|_________ node1: mon1, osd0, osd1        (10.10.2.51)
<br>	|
<br>	|
<br>	|_________ node2: osd2, osd3              (10.10.2.52) 
<br>	|
<br>	|
<br>	|_________ node3: osd4, osd5              (10.10.2.53)

## Installation Process
In general, i divide the installation process into several steps.
1. Set hostname @ each node
2. Set NTP Server (Optional. I will use local NTP Server)
3. Set NTP Client (Optional)
4. Make ceph user
5. Add Ceph Package and install ceph
6. Initializing initial monitor for the cluster 
7. Add OSD

### Hostname Configuration @ Each Node
- Edit hostname configuration
```sh
sudo nano /etc/hostname
```
- Add this line
```sh
10.10.2.51 node1
10.10.2.52 node2
10.10.2.53 node3
```
- Edit /etc/hosts
```sh
sudo nano /etc/hosts
```
- Add this line
```sh
node<node-number>
```
```sh
node1
```

### Set NTP Server and NTP Client
- I will use node1 as local NTP server and node2 and node3 as NTP client
- Install package in each node
```sh
sudo apt-get install -y ntp ntpdate ntp-doc
```
- For each node, configure time zone. I will use UTC in this project.
```sh
sudo dpkg-reconfigure tzdata
```
- Add lines below @ node1
```sh
server 127.127.1.0
fudge 127.127.1.0 stratum 10
```
- Add lines below @ node2 and node3
```sh
server <ip-NTP-local-server> iburst
```
```sh
server 10.10.2.51 iburst
```
- Comment lines below @ node2 and node3
```sh
# Use servers from the NTP Pool Project. Approved by Ubuntu Technical Board
# on 2011-02-08 (LP: #104525). See http://www.pool.ntp.org/join.html for
# more information.
#server 0.ubuntu.pool.ntp.org
#server 1.ubuntu.pool.ntp.org
#server 2.ubuntu.pool.ntp.org
#server 3.ubuntu.pool.ntp.org
```
- Restart NTP Service
```sh
sudo /etc/init.d/ntp restart
```
- Cek NTP connection @ node2 and node3
```sh
ntpq -c lpeer
```

### Make Ceph User @ Each Node
- Make user named ceph
```sh
sudo useradd -m -s /bin/bash <username>
```
```sh
sudo useradd -m -s /bin/bash ceph
```
- Add password for this user
```sh
sudo passwd <username>
```
```sh
sudo passwd ceph
```
- Add the user to sudoers
```sh
echo "<username> ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/<username>
sudo chmod 0440 /etc/sudoers.d/<username>
sudo sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
```
```sh
echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
sudo chmod 0440 /etc/sudoers.d/ceph
sudo sed -i s'/Defaults requiretty/#Defaults requiretty'/g /etc/sudoers
```

### Add Ceph Packages and Install Ceph @ Each Node
- Add Ceph release key
```sh
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
```
- Add Ceph repository. I will add mimic repository. If you want to use another version, you can change mimic to your preferred version
```sh
echo deb https://download.ceph.com/debian-mimic/ xenial main | sudo tee /etc/apt/sources.list.d/ceph.list
```
- Install ceph
```sh
sudo apt install ceph -y
```

### Configure Initial Monitor @node1
- Create unique UUID for your cluster. Copy this unique id. We will use it in cluster config file.
```sh
uuidgen
```
- Make cluster config in /etc/ceph/<cluster-name>.conf
```sh
[global]
fsid = <UUID>
mon_initial_members = <initial-monitor-hostname>
mon_host = <initial-monitor-ip>
auth_cluster_required = cephx	
auth_service_required = cephx
auth_client_required = cephx
```
```sh
[global]
fsid = 0040ace6-ace7-4c69-83d1-da8e082fd282
mon_initial_members = node1
mon_host = 10.10.2.51
auth_cluster_required = cephx	
auth_service_required = cephx
auth_client_required = cephx
```
- Create keyring
```sh
sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
sudo chmod 744 /tmp/ceph.mon.keyring
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd'
```
- Import keyring
```sh
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
```
- Add initial monitor node to monitor map
```sh
monmaptool --create --add <initial-monitor-node> <initial-monitor-ip> --fsid <UUID> /tmp/monmap
sudo ceph-mon --mkfs -i <initial-monitor-hostname> --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```
```sh
monmaptool --create --add node1 10.10.2.51 --fsid 0040ace6-ace7-4c69-83d1-da8e082fd282 /tmp/monmap
sudo ceph-mon --mkfs -i node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```
- Finishing
```sh
sudo touch /var/lib/ceph/mon/ceph-node1/done
```
```sh
sudo touch /var/lib/ceph/mon/<cluster-name>-<initial-monitor-hostname>/done
```
- Repair permissions
```sh
sudo chown -R ceph:ceph /var/lib/<cluster-name>
sudo chmod 744 -R /var/lib/<cluster-name>/
sudo chown -R ceph:ceph /var/lib/<cluster-name>/*
sudo chmod 744 -R /var/lib/<cluster-name>/*
```
```sh
sudo chown -R ceph:ceph /var/lib/ceph
sudo chmod 744 -R /var/lib/ceph/
sudo chown -R ceph:ceph /var/lib/ceph/*
sudo chmod 744 -R /var/lib/ceph/*
```
- Start the monitor
```sh
sudo systemctl start ceph-mon
```
### Adding OSD @ Each Node
- Create UUID for OSD and initialize the OSD. The outcome of this process is OSD number.
```sh
uuidgen
ceph osd create <UUID>
```
```sh
uuidgen
ceph osd create ebca4222-6f1d-4071-939d-a2cf88fe048b
```
- Initialize OSD directory
```sh
sudo mkdir /var/lib/ceph/osd/<cluster-name>-<osd-number>
```
```sh
sudo mkdir /var/lib/ceph/osd/ceph-0
```
- Format flashdisk
```sh
sudo mkfs -t <fstype> /dev/<hdd>
```
```sh
sudo mkfs -t ext4 /dev/sda
```
- Mount flashdisk to OSD directory
```sh
sudo mount /dev/<hdd> /var/lib/ceph/osd/<cluster-name>-<osd-number>
```
```sh
sudo mount /dev/sda /var/lib/ceph/osd/ceph-0
```
- Initialize flashdisk as OSD
```sh
sudo ceph-osd -i <osd-number> --mkfs --mkkey --osd-uuid <UUID>
```
```sh
sudo ceph-osd -i 0 --mkfs --mkkey --osd-uuid ebca4222-6f1d-4071-939d-a2cf88fe048b
```
- Make capabilities for the OSD
```sh
sudo ceph auth add osd.<osd-number> osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/<cluster-name>-<osd-num>/keyring
```
```sh
sudo ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring
```
- Add node bucket to crushmap(optional)
```sh
ceph osd crush add-bucket <hostname> host
```
```sh
ceph osd crush add-bucket node1 host
```
- Move node bucket under root bucket (optional)
```sh
ceph osd crush move <hostname> root=default
```
```sh
ceph osd crush move node1 root=default
```
- Add OSD to Crush Map
```sh
ceph osd crush add osd.<osd-number> <weight> host=<hostname>
```
```sh
ceph osd crush add osd.0 1.0 host=node1
```
- Start the OSD
```sh
sudo systemctl start ceph-osd@<osd-number>
```
```sh
sudo systemctl start ceph-osd@0
```