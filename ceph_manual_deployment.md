# Ceph Manual Deployment
Tested in ubuntu 16.04
## Ceph cluster

<br>ceph-admin 
<br>	|_________ node1: mon1, osd0, osd1, osd3
<br>	|
<br>	|
<br>	|_________ node2: osd4, osd5, osd6 
<br>	|
<br>	|
<br>	|_________ node3: osd7, osd8, osd9

<br>host name           IP address
<br>node1               10.10.2.100
<br>node2               10.10.2.101
<br>node3               10.10.2.102

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
sudo chmod +r etc/ceph/ceph.client.admin.keyring
```
6.Generate a bootstrap-osd keyring, generate a client.bootstrap-osd user and add the user to the keyring.
```
sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd'
```
7.Add the generated keys to the ceph.mon.keyring.
```
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
```
```
sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
```
8.Generate a monitor map using the hostname(s), host IP address(es) and the FSID. Save it as /tmp/monmap:
```
monmaptool --create --add node1 192.168.0.1 --fsid a7f64266-0894-4f1e-a635-d0aeaca0e993 /tmp/monmap
```
9.Change the ceph configuration permission and owner in /var/lib/ceph
```
sudo chown -R ceph:ceph /var/lib/ceph
```
```
sudo chmod 750 -R /var/lib/ceph/
```

note : this configuration use 750 as default permission 

10.Populate the monitor daemon(s) with the monitor map and keyring.
```
sudo -u ceph ceph-mon --mkfs -i node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```
11.Consider settings for a Ceph configuration file. Common settings include the following:
```
[global]
fsid = a93586b1-4423-45b8-8ab7-c5cf0036b258
mon_initial_members = node1
mon_host = 10.10.2.100
auth_cluster_required = cephx	
auth_service_required = cephx
auth_client_required = cephx
```

12.Start the monitor(s).

For most distributions, services are started via systemd now:
```
sudo systemctl start ceph-mon@node1
```

13.Verify that the monitor is running.
```
ceph -s
```

You should see output that the monitor you started is up and running, and you should see a health error indicating that placement groups are stuck inactive. It should look something like this:
```
cluster:
  id:     a7f64266-0894-4f1e-a635-d0aeaca0e993
  health: HEALTH_OK

services:
  mon: 1 daemons, quorum node1
  mgr: node1(active)
  osd: 0 osds: 0 up, 0 in

data:
  pools:   0 pools, 0 pgs
  objects: 0 objects, 0 bytes
  usage:   0 kB used, 0 kB / 0 kB avail
  pgs:
```

Note : the most common failure in running monitor may occour because of keyring permission. therefore each component can't communicate each other based on cephx configuration.

### 3. Create Ceph-mgr
Create ceph-mgr beside of your monitor node. First, create an authentication key for your daemon:
```
ceph auth get-or-create mgr.$name mon 'allow profile mgr' osd 'allow *' mds 'allow *'
```

for example:
```
ceph auth get-or-create mgr.node1 mon 'allow profile mgr' osd 'allow *' mds 'allow *'
```
Place that key into mgr data path, which for a cluster “ceph” and mgr $name “node1” would be /var/lib/ceph/mgr/ceph-node1.

Start the ceph-mgr daemon:
```
ceph-mgr -i $name
```

### 4. Create osd
add a new osd
```
sudo ceph-disk prepare --cluster ceph --cluster-uuid a93586b1-4423-45b8-8ab7-c5cf0036b258 --fs-type ext4 /dev/hdd1
```
activate the osd
```
sudo ceph-disk activate /dev/hdd1
```

### 5. Adding MDS
1.Create the mds data directory
```
mkdir -p /var/lib/ceph/mds/{cluster-name}-{id}
```

2.Create a keyring
```
ceph-authtool --create-keyring /var/lib/ceph/mds/{cluster-name}-{id}/keyring --gen-key -n mds.{id}
```

3.Import the keyring and set caps
```
ceph auth add mds.{id} osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/{cluster}-{id}/keyring
```

4.Add to ceph.conf
```
[mds.{id}]
host = {id}
```

5.Start the daemon the manual way
```
ceph-mds --cluster {cluster-name} -i {id} -m {mon-hostname}:{mon-port} [-f]
```

6.Start the daemon the right way (using ceph.conf entry)
```
service ceph start
```

