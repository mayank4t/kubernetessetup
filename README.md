# kubernetes setup

The script will work only for RPM-based OS image

This repo is created for the kuernetes setup in the GCP platform.
Use scripts/gcpsetup.sh to spin up the cluster, It will also create the master node along with the number of nodes on the basis of user input. 

Below values are hardcoded
Master node:- hostname, Project name, image type, machine size, and zone  
Worker node :- hostname (node1, node2, node3… noden)  Project name, image type, machine size, and zone  

Versions:- 

# Versions kubeadm-1.18.5-0 kubelet-1.18.5-0 kubectl-1.18.5-0

This script will also setup grafana and prometheus monitoring based on the user's input
