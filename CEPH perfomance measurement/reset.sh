#!/bin/bash -x

ceph=`which ceph`
systemctl=`which systemctl`
rm=`which rm`
killall=`which killall`

#deleting metadata server
if  [[ ! -f `$ceph mds stat` ]] ; then
    $systemctl stop ceph-mds@node1
    $killall ceph-mds
    cd /var/lib/ceph/mds
    $rm -R ceph-node1    
    $ceph auth del mds.node1
fi

