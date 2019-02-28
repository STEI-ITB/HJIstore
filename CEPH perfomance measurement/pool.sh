#!/bin/bash 

ceph=`which ceph`

case "$1" in
    erasure)     $ceph osd pool create $1_data 32 32 erasure erasureSSD erasure-code
                 $ceph osd pool create $1_metadata 32  
                 $ceph osd pool set $1_data allow_ec_overwrites true ;;
    replication) $ceph osd pool create $1_data 32 
                 $ceph osd pool create $1_metadata 32 ;;
esac
    
