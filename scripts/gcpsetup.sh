#!/bin/bash

#---------------------------------------------------------------------------------------------#
# This script is used for the configuration of master and worker node
# Script will check for hostname as master 
# If configured it will check for token from master 
# If not configured it will start creating master node
# It will also create worker node and those node can be visible at master using kuberctl get node
#---------------------------------------------------------------------------------------------#

echo "This script will setup a master node as well"
echo "If already configured it will skip master node configuration"
echo "How many worker node you want to setup enter number:-"
read numberofvm ;

# Check for master node with hostname :- master is configured or not 
gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" > /dev/null;

# if master node is not configured it will start creating it using hostname as master
if [ $? -ne 0 ];
then
        gcloud compute instances create master --project=kubernetestestmayank --image=centos-7 --machine-type=e2-medium --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetessetup/master/scripts/master.sh
        # Waiting for Completion of Master node configuration
	gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep -e "------------Master Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on master...";
                sleep 10 ;
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep -e  "------------Master Node configured -------"
        done
	
	# Check for master node configuration for token  
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
               echo "Master Node configuration is completed" ;
        else
                echo "There are some issue with the Master node, Please check" ;
        fi
fi
# Loop for creation of worker node (hostname is like :- node1, node2 , node3 …)
for ((i=1 ; i <=$numberofvm ; i++));
do
        instance=node$i
        echo "creation of $instance begain"
        # creation of worker node
	gcloud compute instances create $instance --project=kubernetestestmayank --image=centos-7 --machine-type=e2-micro --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetessetup/master/scripts/worker.sh
        # Waiting for Completion of worker node configuration
	gcloud compute --project=kubernetestestmayank instances get-serial-port-output $instance --zone=asia-south2-a --port=1 | grep -e "------------Worker Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on worker...";
                sleep 10 ;
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output $instance --zone=asia-south2-a --port=1 | grep -e "------------Worker Node configured -------"
        done
	# get join command for worker node from master node	
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" >> mastertoken.sh
	# copy token to Newley created worker node
        gcloud compute scp --recurse ./mastertoken.sh $instance:/tmp/mastertoken.sh --project=kubernetestestmayank --zone=asia-south2-a ;
	# Join as a node using token
        gcloud compute ssh --zone "asia-south2-a" "$instance"  --project "kubernetestestmayank" --command "sudo /tmp/mastertoken.sh" ;
        rm -rf mastertoken.sh
        echo "worker node created"
done
echo "All Worker node setup complete check using kubectl on master" ;
