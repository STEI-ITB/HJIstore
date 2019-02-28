#!/bin/bash

if [ -n "$1" ]; then
    ceph=`which ceph`
    rbd=`which rbd`

    #creating ceph pool
    case "$1" in
        erasure)     $ceph osd pool create rbd_$1_datapool 32 32 erasure erasureSSD erasure-code
                     $ceph osd pool create rbd_$1_pool 32   
                     $ceph osd pool set rbd_$1_datapool allow_ec_overwrites true ;; 
        replication) $ceph osd pool create rbd_$1_datapool 32 
                     $ceph osd pool create rbd_$1_pool 32 ;;
    esac

    #creating the block device
    $rbd pool init rbd_$1_pool
    $rbd create rbd_$1_pool/$1_rbd --size 4G --data-pool rbd_$1_datapool

    if [ $1 == "erasure" ] ; then
        $rbd feature disable rbd_$1_pool/$1_rbd object-map fast-diff deep-flatten
    fi
else
    echo "No parameters found"
    echo "try use ./cephfs.sh <erasure/replication>"
fi

