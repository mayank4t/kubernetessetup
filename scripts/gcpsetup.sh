echo "This script will setup a master node as well"
echo "If already configured it will skip master node configuration"
gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "kubeadm token create --print-join-command" ;
if [ $? -ne 0 ];
then
        gcloud compute instances create master --project=kubernetestestmayank --image=centos-7 --machine-type=e2-medium --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/master.sh
        flag1=2
        while [ ! $flag1 -eq 0 ]
        do
                gcloud compute --project=kubernetestestmayank instances get-serial-port-output master --zone=asia-south2-a --port=1 | grep "------------Master Node configured -------"
                flag1="$?"
        done
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
               echo "Master Node configuration is completed" ;              
        else
                echo "There are some issue with the Master node, Please check" ;
        fi
fi
echo "How many worker node you want to setup enter number:-"
read numberofvm ;
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
        gcloud compute scp --recurse ./mastertoken.sh $instance:/tmp/mastertoken.sh --project=kubernetestestmayank --zone=asia-south2-a ;
        gcloud compute ssh --zone "asia-south2-a" "$instace"  --project "kubernetestestmayank" --command "chmod +x /tmp/mastertoken.sh" ;
        gcloud compute ssh --zone "asia-south2-a" "$instance"  --project "kubernetestestmayank" --command "/tmp/mastertoken.sh" ;
        rm -rf mastertoken.sh ;
}
