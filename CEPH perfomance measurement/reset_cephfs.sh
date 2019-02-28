#!/bin/bash

if [ -n "$1" ]; then
    ceph=`which ceph`
    systemctl=`which systemctl`
    rm=`which rm`
    killall=`which killall`

    #deleting metadata server if available
    if  $ceph mds stat | grep 'up' ; then
        $systemctl stop ceph-mds@node1
        $killall ceph-mds
        cd /var/lib/ceph/mds
        $rm -R ceph-node1    
        $ceph auth del mds.node1
    fi

    #deleting filesystem
    $ceph fs rm $1 --yes-i-really-mean-it

    #deleting osd data & metadata
    $ceph osd pool delete $1_data $1_data --yes-i-really-really-mean-it
    $ceph osd pool delete $1_metadata $1_metadata --yes-i-really-really-mean-it

else
    echo "No parameters found"
    echo "try use ./cephfs.sh <Ceph file system name>"
    echo "run 'ceph fs ls' for filesystem list "
fi