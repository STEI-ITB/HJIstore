# Demystifying Ceph Storage Cluster 4.0

We're going to deploy a Ceph Cluster using the configuration below:

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

This wiki was compilated from many sources scattered throughout the internet, especially from the official Ceph and Red Hat Documentations. Tested on Ubuntu 16.04 but should work on any newer versions.

Note : Multiple OSD in one physical hardisk will decrease the performance
