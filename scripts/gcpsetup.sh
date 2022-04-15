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
echo "Please share Node Type for worker node, supported are:- e2-micro , e2-small" ;
read workernodetype ;
read -r -p "Do you want to setup grafana and Prometheus for your cluster? [y/n] " input

# -------------------------------Hardcoaded values----------------------------------#
# Setting up worker node type to e2-small or e2-micro
while [[ "$workernodetype" != "e2-small" && "$workernodetype" != "e2-micro" ]]
do
        echo "Please share Node Type for worker node, supported are:- e2-micro , e2-small" ;
        read workernodetype ;
done
while [[ "$input" != "y" && "$input" != "n" ]]
do
        echo "Enter y for Yes and n for No" ;
        read input;
done
project=kubernetestestmayank;
zone=asia-south2-a;
masternodetype=e2-medium;
image=centos-7;
hostnamemaster=master;
#------------------------------------------------------------------------------------#

# Check for master node with hostname :- master is configured or not 
gcloud compute ssh --zone $zone $hostnamemaster  --project $project --command "sudo kubeadm token create --print-join-command" > /dev/null;

#---------------------------------------Master node configuration----------------------#
# if master node is not configured it will start creating it using hostname as master
if [ $? -ne 0 ];
then
        gcloud compute instances create $hostnamemaster --project=$project --image=$image --machine-type=$masternodetype --zone=$zone --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetessetup/master/scripts/master.sh
        # Waiting for Completion of Master node configuration
	gcloud compute --project=$project instances get-serial-port-output $hostnamemaster --zone=$zone --port=1 | grep -e "------------Master Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on master...";
                sleep 10 ;
                gcloud compute --project=$project instances get-serial-port-output $hostnamemaster --zone=$zone --port=1 | grep -e  "------------Master Node configured -------"
        done
	
	# Check for master node configuration for token  
        gcloud compute ssh --zone $zone $hostnamemaster  --project $project --command "sudo kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
               echo "Master Node configuration is completed" ;
        else
                echo "There are some issue with the Master node, Please check" ;
        fi
fi
#---------------------------------------------------------------------------------------#
# Loop for creation of worker node (hostname is like :- node1, node2 , node3 …)
#---------------------------Worker Node Configuration ------------------------------------#
for ((i=1 ; i <=$numberofvm ; i++));
do
        instance=node$i
        echo "creation of instance $instance with resource type as $workernodetype begain"
        # creation of worker node
	gcloud compute instances create $instance --project=$project --image=$image --machine-type=$workernodetype --zone=$zone --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetessetup/master/scripts/worker.sh
        # Waiting for Completion of worker node configuration
	gcloud compute --project=$project instances get-serial-port-output $instance --zone=$zone --port=1 | grep -e "------------Worker Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on worker...";
                sleep 10 ;
                gcloud compute --project=$project instances get-serial-port-output $instance --zone=$zone --port=1 | grep -e "------------Worker Node configured -------"
        done
	# get join command for worker node from master node	
        gcloud compute ssh --zone $zone "master"  --project $project --command "sudo kubeadm token create --print-join-command" >> mastertoken.sh
	# copy token to Newley created worker node
        gcloud compute scp --recurse ./mastertoken.sh $instance:/tmp/mastertoken.sh --project=$project --zone=$zone ;
	# Join as a node using token
        gcloud compute ssh --zone $zone "$instance"  --project $project --command "sudo sh /tmp/mastertoken.sh" ;
        rm -rf mastertoken.sh
        echo "worker node created"
done
#---------------------------------------------------------------#

#--------------------------------- Monitoring Configuration -----------------------------------------#
if [ $input = "y" ];
then
	wget "https://raw.githubusercontent.com/mayank4t/prometheus-grafanaK8setup/main/master.sh"
	gcloud compute scp --recurse ./master.sh $hostnamemaster:/tmp/master.sh --project=$project --zone=$zone;
	gcloud compute ssh --zone $zone $hostnamemaster --project $project --command "sudo sh /tmp/master.sh" ;
	echo "Master node configured"
	for ((i=1 ; i <=$numberofvm ; i++));
	do
		instance=node$i
		gcloud compute ssh --zone $zone "$instance"  --project $project --command "sudo yum install nfs-utils -y"
		gcloud compute ssh --zone $zone "$instance"  --project $project --command "sudo mkdir /data"
		gcloud compute ssh --zone $zone "$instance"  --project $project --command "sudo mount -t nfs  master:/data /data"

	done
	echo "Configured all worker with nfs mount"
	echo "All Worker node setup complete check using kubectl on master" ;
else 
	echo "All Worker node setup complete without monitoring, check using kubectl on master" ;
fi
#----------------------------------------------------------------------------------------------------------#
