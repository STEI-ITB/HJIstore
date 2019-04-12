#!/bin/bash 

createPool(){
    case $1 in
    erasure)     $ceph osd pool create $1_data 32 32 erasure erasureSSD erasure_code_ssd
                 $ceph osd pool create $1_metadata 32 
                 $ceph osd pool set $1_data allow_ec_overwrites true;; 
    replicated) $ceph osd pool create $1_data 32 32 replicated replicated_rule_ssd 
                 $ceph osd pool create $1_metadata 32 ;;
    esac
}

createMds(){
    cd /var/lib/ceph/mds
    $mkdir ceph-node1
    $chown -R ceph:ceph ceph-node1
    $chmod 755 ceph-node1 
    $ceph-authtool --create-keyring /var/lib/ceph/mds/ceph-node1/keyring --gen-key -n mds.node1
    $chown -R ceph:ceph /var/lib/ceph/mds/ceph-node1
    $chmod 755 /var/lib/ceph/mds/ceph-node1
    $ceph auth add mds.node1 osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/ceph-node1/keyring
    $sudo systemctl stop ceph-mds@node1
    $sudo systemctl enable ceph-mds@node1
    $sudo systemctl start ceph-mds@node1
    $ceph-mgr -i node1
}

if [ -n "$1" ]; then
    ceph=`which ceph`
    mkdir=`which mkdir`
    chown=`which chown`
    chmod=`which chmod`
    systemctl=`which systemctl`
    killall=`which killall`

    filesystem=$1

    #checking for available metadata server
    if  $ceph mds stat | grep 'up' ; then
        echo "metadata server available"
        createPool "$filesystem" "$filesystem"   
    else
        echo "no available metadata server"
        #createMds
        createPool "$filesystem" "$filesystem"
    fi  
    
    #creating new cephfs
    $ceph fs new $1 $1_metadata $1_data

    #Filesystem status
    $ceph mds stat
else
    echo "No parameters found"
    echo "try use ./cephfs.sh <erasure/replicated>"
fi

