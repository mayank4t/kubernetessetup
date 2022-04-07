# kubernetes setup

kubernetes setup,
This repo is created for the kuernetes setup in the GCP platform.
Use ./gcpsetup.sh to spin up the cluster, It will also create the master node along with the number of nodes on the basis of user input. 

Below values are hardcoded
Master node :- hostname, Project name, image type, machine size, and zone  
Worker node :- hostname (node1, node2, node3… noden)  Project name, image type, machine size, and zone  

To use this :-

Update gcpsetup.sh for above mentioned values.
