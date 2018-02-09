#!/bin/bash
[[ $TRACE ]] && set -x
set +e
###############################################
# Check current user
###############################################

if [[ `whoami` = "root" ]];
then
	echo "Hello, user root."
else
	echo "Please enter the password of user root."
	su
fi

###############################################
# Check docker installation
###############################################
docker info > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Install docker ..."
	yum install -y docker
	systemctl enable docker.service && systemctl start docker.service
fi

###############################################
# Check git installation
###############################################
git --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Install git ..."
	yum install -y git
fi

set -e
###############################################
# Clone RPM package
###############################################
echo "Downloading RPM packages, this may take a while ..."
if [ ! -d `pwd`/"rpm" ]; then
  git clone https://github.com/rivernetio/rpm
fi
cd rpm && git pull
cd ..

echo "RPM packages downloaded successfully."

###############################################
# Download ECP Charts
###############################################
echo "Downloading ECP Charts, this may take a while."
if [ ! -d `pwd`/"charts" ]; then
  git clone https://github.com/rivernetio/charts
fi
cd charts && git pull
cd ..

echo "ECP Charts downloaded successfully."

##############################################################
# Configure docker image accelerator provided by Alibaba Cloud
##############################################################
if [ "$SITE" != "Toronto" -a "$SITE" != "TORONTO" ]; then
tee /etc/docker/daemon.json <<-'EOF'
{
	"registry-mirrors": ["https://1gbxn0j2.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
echo "Docker image accelerator configured successfully."
fi

GOOGLE_IMAGES=(
	k8s-dns-sidecar-amd64:1.14.4
	k8s-dns-kube-dns-amd64:1.14.4
	k8s-dns-dnsmasq-nanny-amd64:1.14.4
	kube-apiserver-amd64:v1.7.5
	kube-controller-manager-amd64:v1.7.5
	kube-scheduler-amd64:v1.7.5.1
	kube-proxy-amd64:v1.7.5
	etcd-amd64:3.0.17
)

MANAGEMENT_IMAGES=(
	docker.io/rivernet/kube-apiserver-amd64:v1.7.5
	docker.io/rivernet/kube-controller-manager-amd64:v1.7.5
	docker.io/rivernet/kube-scheduler-amd64:v1.7.5.1
	docker.io/rivernet/etcd-amd64:3.0.17
	docker.io/rivernet/rudder:4.2
	docker.io/rivernet/tiller:v2.6.2
	docker.io/rivernet/helm:v2.2.3
	docker.io/rivernet/canes:4.2
	docker.io/rivernet/elasticsearch:5.6.4
	docker.io/rivernet/kibana:5.6.4
	docker.io/rivernet/docker-elasticsearch-curator:5.4.1
	docker.io/rivernet/events:4.2
	docker.io/rivernet/license:4.2
	docker.io/rivernet/lyra:4.2
	docker.io/rivernet/mysql-sky:4.2
	docker.io/rivernet/curl:latest
	docker.io/rivernet/grafana-sky:4.2
	docker.io/rivernet/kube-state-metrics:v0.5.0
	docker.io/rivernet/kube-api-exporter:master-2fe5dfb
	docker.io/rivernet/prometheus:v1.5.2
	docker.io/rivernet/k8s-prometheus-adapter:v0.2.0-beta.0
	docker.io/rivernet/pyxis:4.2
	docker.io/rivernet/river:4.2
	docker.io/rivernet/keystone:20161108
	docker.io/rivernet/skyform-sas:4.2
	docker.io/rivernet/ara:4.2
)

CLUSTER_IMAGES=(
	docker.io/rivernet/k8s-dns-sidecar-amd64:1.14.4
	docker.io/rivernet/k8s-dns-kube-dns-amd64:1.14.4
	docker.io/rivernet/k8s-dns-dnsmasq-nanny-amd64:1.14.4
	docker.io/rivernet/kube-proxy-amd64:v1.7.5
	docker.io/rivernet/pause-amd64:3.0
	docker.io/rivernet/kubernetes-dashboard-amd64:v1.6.3
	docker.io/rivernet/etcd:v3.1.10
	docker.io/rivernet/node:v2.4.1
	docker.io/rivernet/cni:v1.10.0
	docker.io/rivernet/kube-policy-controller:v0.7.0
	docker.io/rivernet/flannel:v0.7.1-amd64
	docker.io/rivernet/fluentd-elasticsearch:v2.0.2
	docker.io/rivernet/node-exporter:0.12.0
)

HARBOR_IMAGES=(
	docker.io/rivernet/harbor-ui:4.2
	docker.io/rivernet/harbor-proxy:4.2
	docker.io/rivernet/harbor-mysql:4.2
	docker.io/rivernet/harbor-registry:4.2
	docker.io/rivernet/docker:stable-dind
)

APP_IMAGES=(
	docker.io/rivernet/jupyter:4.2
	docker.io/rivernet/tensorflow-serving:4.2
	docker.io/rivernet/tensorflow:4.2
	docker.io/rivernet/web-vote-app:v0.1
	docker.io/rivernet/redis:3.0
	docker.io/rivernet/redis_exporter:v0.14
	docker.io/rivernet/curl:latest
	docker.io/rivernet/tomcat:8.0.47-r0
	docker.io/rivernet/mnist-demo:4.2
        docker.io/rivernet/mysql:5.7.20
        docker.io/rivernet/mysqld-exporter:latest
        docker.io/rivernet/nvidia-smi-exporter:8.0-runtime-ubuntu14.04
)

GLUSTER_IMAGES=(
	docker.io/rivernet/gluster-centos:latest
	docker.io/rivernet/heketi:dev
)

function is_google_image() {
	image=$1
	googleImage=""
	for imageName in ${GOOGLE_IMAGES[@]}; do
		if [[ $image == *$imageName ]]; then
			googleImage=$imageName
		fi
	done
}

function retry() {
	n=0
	until [ $n -ge 5 ]
	do
		"$@" && return $?
		n=$[$n+1]
		sleep 1
	done
	return 1
}

###############################################
# x86_64 Package
###############################################
function create_x86_64_package() {
	
	# image_tars/cluster 
	#  - CLUSTER_IMAGES
	# image_tars/management
	#  - MANAGEMENT_IMAGES
	#  - HARBOR_IMAGES
	# image_tars/charts
	#  - APP_IMAGES
	# image_tars/gluster
	#  - GLUSTER_IMAGES
	mkdir -p image_tars/{cluster,management,charts,gluster}

	# Generate images for all hosts in the cluster
	local images=
	for image in ${CLUSTER_IMAGES[@]}; do
		retry docker pull $image
		is_google_image $image
		if [ "$googleImage" ]; then
			echo "tag $image to gcr.io/google_containers/$googleImage"
			docker tag $image gcr.io/google_containers/$googleImage
			images="$images gcr.io/google_containers/$googleImage"
		else
			images="$images $image"
		fi
	done

	echo
	echo "Generating cluster nodes images, this may take a while."
	echo
	docker save  $images > image_tars/cluster/ecp-cluster.tar

	# Generate images for management hosts
	images=""
	for image in ${MANAGEMENT_IMAGES[@]}; do
		retry docker pull $image
		is_google_image $image
		if [ "$googleImage" ]; then
			echo "tag $image to gcr.io/google_containers/$googleImage"
			docker tag $image gcr.io/google_containers/$googleImage
			images="$images gcr.io/google_containers/$googleImage"
		else
			images="$images $image"
		fi
	done

        docker tag docker.io/rivernet/kube-scheduler-amd64:v1.7.5.1 gcr.io/google_containers/kube-scheduler-amd64:v1.7.5
        images="$images gcr.io/google_containers/kube-scheduler-amd64:v1.7.5"

	echo
	echo "Generating management nodes images, this may take a while."
	echo
	docker save  $images > image_tars/management/ecp-management.tar

	# Generate images for harbor hosts
	images=""
	for image in ${HARBOR_IMAGES[@]}; do
		retry docker pull $image
		images="$images $image"
	done

	echo
	echo "Generating harbor images, this may take a while."
	echo
	docker save  $images > image_tars/management/ecp-harbor.tar

	# Generate images for application store
	images=""
	for image in ${APP_IMAGES[@]}; do
		retry docker pull $image
		images="$images $image"
	done

	echo
	echo "Generating app images, this may take a while."
	echo
	docker save  $images > image_tars/charts/ecp-charts.tar

	images=""
	for image in ${GLUSTER_IMAGES[@]}; do
		retry docker pull $image
		images="$images $image"
	done

	# Generate images for glusterfs hosts
	echo
	echo "Generating gluster images, this may take a while."
	echo
	docker save  $images > image_tars/gluster/ecp-glusters.tar
}

create_x86_64_package
echo "x86_64 offline package created successfully."



