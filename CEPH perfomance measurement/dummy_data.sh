#!/bin/bash

rados=`which rados`

for i in `seq 1 1000000`; do
    $rados put tes"$i" /home/cephuser/data --pool=cephfs_data
done
    
    