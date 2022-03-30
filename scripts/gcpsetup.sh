echo "This script will setup a master node as well"
echo "If already configured it will skip master node configuration"
echo "How many worker node you want to setup enter number:-"
read instance
instace=node$instase
gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "kubeadm token create --print-join-command" | grep join >> mastertoken.sh ;
if [ $? -eq 0 ];
then
        for release in $@
        do
                gcloud compute instances create $instance --project=kubernetestestmayank --image=centos-7 --machine-type=e2-micro --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/worker.shi ;
                gcloud compute scp --recurse ./mastertoken.sh $instance:/tmp/mastertoken.sh --project=kubernetestestmayank --zone=asia-south2-a ;
                gcloud compute ssh --zone "asia-south2-a" "$instace"  --project "kubernetestestmayank" --command "chmod +x /tmp/mastertoken.sh" ;
                gcloud compute ssh --zone "asia-south2-a" "$instance"  --project "kubernetestestmayank" --command "/tmp/mastertoken.sh" ;
        done
else
        gcloud compute instances create node01 --project=kubernetestestmayank --image=centos-7 --machine-type=e2-micro --zone=asia-south2-a --metadata=startup-script-url=https://raw.githubusercontent.com/mayank4t/kubernetes/master/scripts/worker.sh ;
        gcloud compute ssh --zone "asia-south2-a" "master"  --project "kubernetestestmayank" --command "kubeadm token create --print-join-command" ;
        if [ $? -eq 0 ];
        then
                echo "There are some issue with the Master node, Please check" ;
        else
                echo "Master Node configuration is completed" ;
        fi
fi
rm -rf mastertoken.sh
