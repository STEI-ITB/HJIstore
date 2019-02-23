# Mini Ceph Pie
## Introduction
This project was adapted from an existing project. You can check the original one in: https://github.com/GitHippo/Ceph-Pi.
I made some modification:
- This project use manual step installation. Installation process includes inital monitor and OSD. When i try ceph-deploy, i encountered some problems related to repository. I can't find some packages, for example: ceph-osd.
- This project uses mimic version

## Tools and Material Needed
- Raspberry Pi 3x
- MicroSD 16 GB 3x
- Ethernet cable 3x for cluster, 1x for public network.
- Switch
- Flashdisk 32GB 6x. Each Rasp-Pi will handle up to 2 OSD.
- Laptop (optional, for configuration. I use SSH to configure the Rasp-Pi through my laptop)

## Topology
node1-----------|
10.10.2.51      |
(initial mon)   |
                |
node2--------------------------------- Switch----------- Internet------------My Laptop
10.10.2.52      |
                |
node3-----------|
10.10.2.53

## Installation Process
In general, i divide the installation process into several steps.
1. Set hostname for each node
2. Set NTP Server (Optional. I will use local NTP Server)
3. Set NTP Client (Optional)
4. Make ceph user
5. Add Ceph Package and install ceph
6. Initializing initial monitor for the cluster 
7. Make OSD

### Hostname Configuration
- In each node, edit hostname configuration
```sh
sudo nano /etc/hostname
```
- Add this line
```sh
10.10.2.51 node1
10.10.2.52 node2
10.10.2.53 node3
```
- In each node, edit /etc/hosts
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
- Add lines below for node1
```sh
server 127.127.1.0
fudge 127.127.1.0 stratum 10
```
- Add lines below for node2 and node3
```sh
server <ip-NTP-local-server> iburst
```
```sh
server 10.10.2.51 iburst
```
- Comment lines below for node2 and node3
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
- Cek NTP connection in node2 and node3
```sh
ntpq -c lpeer
```

### Make Ceph User
- In each node, make user named ceph
```sh
sudo useradd -m -s /bin/bash <username>
```
```sh
sudo useradd -m -s /bin/bash ceph
```
- In each node, add password for this user
```sh
sudo passwd <username>
```
```sh
sudo passwd ceph
```
- In each node, add the user to sudoers
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

### Add Ceph Packages and Install Ceph
- In each node, add Ceph release key
```sh
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
```
- In each node, add Ceph repository. I will add mimic repository. If you want to use another version, you can change mimic to your preferred version
```sh
echo deb https://download.ceph.com/debian-mimic/ xenial main | sudo tee /etc/apt/sources.list.d/ceph.list
```
- In each node, install ceph
```sh
sudo apt install ceph -y
```

