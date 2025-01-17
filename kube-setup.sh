#!/bin/bash
#
# verified on Fedora 31, 33 and Ubuntu LTS 20.04

echo this script works on Fedora 31, 33 and Ubuntu 20.04
echo it does NOT currently work on Fedora 32
echo it requires the machine where you run it to have 6GB of RAM or more
echo press Enter to continue
read

##########
echo ########################################
echo WARNING
echo ########################################
echo Nov 2020 - currently this script is NOT supported on Mac OS Big Sur
echo I will communicate here one Apple/VMware have provided updates that make it work again
echo
echo Check the Setup Guide provided in this repository for alternative installations
echo
echo press Enter to continue
read

# setting MYOS variable
MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
OSVERSION=$(hostnamectl | awk '/Operating/ { print $4 }')

egrep '^flags.*(vmx|svm)' /proc/cpuinfo || (echo enable CPU virtualization support and try again && exit 9)

# debug MYOS variable
echo MYOS is set to $MYOS

#### Fedora config
if [ $MYOS = "Fedora" ]
then
	if [ $OSVERSION = 32 ]
	then
		echo Fedora 32 is not currently supported
		exit 9
	fi
	
	sudo dnf clean all
	sudo dnf -y upgrade

	# install KVM software
	sudo dnf install @virtualization -y
	sudo systemctl enable --now libvirtd
	sudo usermod -aG libvirt vagrant
fi

### Ubuntu config
if [ $MYOS = "Ubuntu" ]
then
	sudo apt-get update -y 
	sudo apt-get install -y apt-transport-https curl
	sudo apt-get upgrade -y
	sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

	sudo adduser `id -un` libvirt
	sudo adduser `id -un` kvm
fi

# install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# install minikube
echo downloading minikube, check version
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo chmod +x minikube
sudo mv minikube /usr/local/bin

#Added minikube to the autorun
touch /etc/profile.d/minikube.sh
echo \#\!\/bin\/sh >> /etc/profile.d/minikube.sh
echo minikube start --memory 4096 --vm-driver=kvm2 >> /etc/profile.d/minikube.sh
chmod +x /etc/profile.d/minikube.sh

#Kubect completion
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl

#Install oh-my-bash
bash -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"

#vim configure
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" >> ~/.vimrc
echo ":set number" >> ~/.vimrc

sudo chown -R vagrant:vagrant ckad/

#Docker config
sudo groupadd docker
sudo usermod -aG docker vagrant
mkdir /sys/fs/cgroup/systemd
mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
sudo systemctl enable docker.service
sudo systemctl enable docker.socket


# start minikube
runuser -l vagrant -c 'minikube start --memory 4096 --vm-driver=kvm2'

echo if this script ends with an error, restart the virtual machine
echo and manually run minikube start --memory 4096 --vm-driver=kvm2
