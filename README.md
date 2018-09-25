# localkube

This project helps to run a single node Kuberentes deployment using the local docker daemon.
There are a few challenges to doing this right now that this repo tries to overcome.

1. Since a local dev env is likely to move between networks we need the kubelet to not be dependent on the current network during install. This natually means using the loopback interface. But kubeadm/kubelet do not work when using a 127.0.0.0/8 IP, so we must add another IP to the loopback interface.
2. We taint the master node to allow pods to be scheduled on it.
3. We add the basics to get hostpath PVC working.
4. Turn off swap for the kubelet process and ignore swap errors.

With those exceptions this project just calls the kubeadm init command to initialize a new kubelet on the local machine.

To use set these env vars if the defaults are not sufficient:

* DOMAIN - the domain for the k8s cluster - defaults to cluster.local
* IP - the IP to add to the loopback - defaults to 10.1.1.1
* INTERFACE - the name of the loopback interface or another "stable" interface - defaults to lo

Once those env vars are set run the `install.sh` script.

The current version of this script uses v1.11 of kubeadm.
