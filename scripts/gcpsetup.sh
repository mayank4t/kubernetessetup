#!/bin/bash
echo "This script will setup a master node as well"
echo "If already configured it will skip master node configuration"
echo "How many worker node you want to setup enter number:-"
read numberofvm ;
gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" > /dev/null;
if [ $? -ne 0 ];
then
        gcloud compute instances create master --project=kubernetestestmayank --image=centos-7 --machine-type=e2-medium --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/master.sh
        gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep -e "------------Master Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on master...";
                sleep 2 ;
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep -e  "------------Master Node configured -------"
        done
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
               echo "Master Node configuration is completed" ;
        else
                echo "There are some issue with the Master node, Please check" ;
        fi
fi
for ((i=1 ; i <=$numberofvm ; i++));
do
        instance=node$i
        echo "creation of $instance begain"
        gcloud compute instances create $instance --project=kubernetestestmayank --image=centos-7 --machine-type=e2-micro --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/worker.sh
        gcloud compute --project=kubernetestestmayank instances get-serial-port-output $instance --zone=asia-south2-a --port=1 | grep -e "------------Worker Node configured -------"
        while [ $? -ne 0 ];
        do
                echo "working on worker...";
                sleep 2 ;
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output $instance --zone=asia-south2-a --port=1 | grep -e "------------Worker Node configured -------"
        done
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" >> mastertoken.sh
        gcloud compute scp --recurse ./mastertoken.sh $instance:/tmp/mastertoken.sh --project=kubernetestestmayank --zone=asia-south2-a ;
        gcloud compute ssh --zone "asia-south2-a" "$instance"  --project "sudo kubernetestestmayank" --command "/tmp/mastertoken.sh" ;
        rm -rf mastertoken.sh
        echo "worker node created"
done
echo "All Worker node setup complete check using kubectl on master" ;
