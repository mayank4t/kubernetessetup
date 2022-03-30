echo "This script will setup a master node as well"
echo "If already configured it will skip master node configuration"
echo "How many worker node you want to setup enter number:-"
read numberofvm ;
gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" ;
if [ $? -ne 0 ];
then
        gcloud compute instances create master --project=kubernetestestmayank --image=centos-7 --machine-type=e2-medium --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/master.sh
        flag1=2
        while [ ! $flag1 -eq 0 ]
        do
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep "------------Master Node configured -------"
                flag1="$?"
        done
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
               echo "Master Node configuration is completed" ;              
        else
                echo "There are some issue with the Master node, Please check" ;
        fi
fi
for (( i = 0; i <= $numberofvm; i++ ))
do
        instance=node$numberofvm
        workernode
        echo "worker node $instace created"
done
echo "All Worker node setup complete check using kubectl on master" ;
function workernode
{
        gcloud compute instances create $instance --project=kubernetestestmayank --image=centos-7 --machine-type=e2-micro --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/worker.sh ;
        flag2=2
        while [ ! $flag2 -eq 0 ]
        do
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output $instance --zone=asia-south2-a --port=1 | grep "------------Worker Node configured -------"
                flag2="$?"
        done
        token=gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "sudo kubeadm token create --print-join-command" ;
        gcloud compute ssh --zone "asia-south2-a" "$instance"  --project "kubernetestestmayank" --command "$token" ;
 }
