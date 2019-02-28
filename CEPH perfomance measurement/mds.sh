#!/bin/bash 

ceph=`which ceph`
ceph-authtool=`which ceph-authtool`
mkdir=`which mkdir`
chown=`which chown`
chmod=`which chmod`
systemctl=`which systemctl`

$mkdir -p /var/lib/ceph/mds/ceph-node1
$chown -R ceph:ceph /var/lib/ceph/mds/ceph-node1
$chmod 755 ceph-node1
$ceph-authtool --create-keyring /var/lib/ceph/mds/ceph-node1/keyring --gen-key -n mds.node1
$chown -R ceph:ceph /var/lib/ceph/mds/ceph-node1
$chmod 755 /var/lib/ceph/mds/ceph-node1
$ceph auth add mds.node1 osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/ceph-node1/keyring
$sudo systemctl stop ceph-mds@node1
$sudo systemctl enable ceph-mds@node1
$sudo systemctl start ceph-mds@node1
$ceph-mgr -i node1

