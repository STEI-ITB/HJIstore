# Ceph Manual Deployment
Tested in ubuntu 16.04
## Ceph cluster

ceph-admin 
	|_________ node1: mon1, osd0, osd1, osd3
	|
	|
	|_________ node2: osd4, osd5, osd6 
	|
	|
	|_________ node3: osd7, osd8, osd9

host name           IP address
node1               10.10.2.100
node2               10.10.2.101
node3               10.10.2.102

Note : Multiple OSD in one physical hardisk will decrease the performance
## Building a Cluster
### 1. Installing ceph

set up your own proxy (apt proxy, wget proxy, etc)

Add the release key: 
```
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
``` 

Add package: (the newest stable version)
```
echo deb https://download.ceph.com/debian-mimic/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
```
	
Update & Install:
```
sudo apt update
sudo apt install ceph
```

in case you need to uninstall it:
```
sudo apt purge ceph-common && sudo apt autoremove
```

### 2. Create a initial monitor
1.Create a Ceph configuration file. By default, Ceph uses ceph.conf, where ceph reflects the cluster name.
```
sudo nano /etc/ceph/ceph.conf
```
2.Generate a unique ID (i.e., fsid) for your cluster.
```
uuidgen
```
3.Add the unique ID, initial monitor, and monitor host to your Ceph configuration file for example:
```
fsid = a7f64266-0894-4f1e-a635-d0aeaca0e993
mon initial members = node1
mon host = 10.10.2.100
```
4.Create a keyring for your cluster and generate a monitor secret key.
```
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```
change with following permission:
```
sudo chmod 750 /tmp/ceph.mon.keyring
```
5.Generate an administrator keyring, generate a client.admin user and add the user to the keyring.
```
sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
```
change with following permission:
```
sudo chmod +r /tmp/ceph.mon.keyring
```
6.Generate a bootstrap-osd keyring, generate a client.bootstrap-osd user and add the user to the keyring.
```
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd'
```

