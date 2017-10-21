# ECP Ansible Playbook
Build an ECP cluster using Ansible. The underlying kubernetes is installed with Kubeadm

## System requirement:
* Deploy node must have `Ansible v2.1.0+` installed.
* All Master/Node should have password-less access from Deploy node.
* All hosts must have `Docker` installed. Verified with `Docker 1.12`.
* Verified on `CentOS 7.3`

## Install
### Add the system information into `inventory`. For example:
```
[master]
10.211.64.107

[node]
10.211.64.109

[cluster:children]
master
node
```

### Customize ```group_vars/all.yml```
Modify the following variables according to your site
```sh
kubeadm_image_repository: gcr.io/google_containers

k8s_dashboard_image: gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3

calico_etcd_image: quay.io/coreos/etcd:v3.1.10
calico_node_image: quay.io/calico/node:v2.4.1
calico_cni_image: quay.io/calico/cni:v1.10.0
calico_policy_controller_image: quay.io/calico/kube-policy-controller:v0.7.0

# appstore
rudder_image: docker.io/rivernet/rudder:20170626
tiller_image: docker.io/rivernet/tiller:v2.2.3
# logging
canes_image: docker.io/rivernet/canes:20170626
elasticsearch_image: docker.io/rivernet/elasticsearch:1.5.2
fluentd_image: docker.io/rivernet/fluentd-elasticsearch:1.22
# events
events_image: docker.io/rivernet/events:20170626
# license
license_image: docker.io/rivernet/license:20170626
# lyra
lyra_image: docker.io/rivernet/lyra:20170626
# mysql
mysql_image: docker.io/rivernet/mysql-sky:20170626
# prometheus
grafana_image: docker.io/rivernet/grafana-sky:20170626
docker_image: docker.io/rivernet/docker
kubestatemetrics_image: quay.io/coreos/kube-state-metrics:v0.5.0
nodeexporter_image: quay.io/prometheus/node-exporter:0.12.0
kubeapiexporter_image: docker.io/rivernet/kube-api-exporter
prometheus_image: quay.io/prometheus/prometheus:v1.5.2
# pyxis
pyxis_image: docker.io/rivernet/pyxis:20170626
# river
river_image: docker.io/rivernet/river:20170626
# sas
keystone_image: docker.io/rivernet/keystone:20161108
sas_image: docker.io/rivernet/skyform-sas:20170626
```
The following image still needs to be tagged, as ``kubeadm`` cannot get the image from ``kubeadm_image_repository``

```gcr.io/google_containers/pause-amd64:3.0```

### Run the `site.yml` playbook:
```sh
$ ansible-playbook -v site.yml
...
TASK [ecp : Create pyxis rc] ************************************************************************************************************
changed: [10.211.64.107] => {"changed": true, "cmd": "kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f /etc/kubernetes/ecp/pyxis/pyxis-controller.yaml", "delta": "0:00:00.249539", "end": "2017-10-20 21:35:58.130390", "rc": 0, "start": "2017-10-20 21:35:57.880851", "stderr": "", "stderr_lines": [], "stdout": "replicationcontroller \"firmament-pyxis\" created", "stdout_lines": ["replicationcontroller \"firmament-pyxis\" created"]}

TASK [ecp : Check if pyxis service already exists] **************************************************************************************
changed: [10.211.64.107] => {"changed": true, "cmd": "kubectl --kubeconfig=/etc/kubernetes/admin.conf get svc --namespace=sky-firmament | grep firmament-pyxis", "delta": "0:00:00.124027", "end": "2017-10-20 21:35:58.593534", "failed": false, "failed_when_result": false, "rc": 1, "start": "2017-10-20 21:35:58.469507", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}

TASK [ecp : Create pyxis svc] ***********************************************************************************************************
changed: [10.211.64.107] => {"changed": true, "cmd": "kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f /etc/kubernetes/ecp/pyxis/pyxis-service.yaml", "delta": "0:00:00.176530", "end": "2017-10-20 21:35:59.037876", "rc": 0, "start": "2017-10-20 21:35:58.861346", "stderr": "", "stderr_lines": [], "stdout": "service \"pyxis-firmament-com\" created", "stdout_lines": ["service \"pyxis-firmament-com\" created"]}

TASK [ecp : Wait until pyxis pod starts to run] *****************************************************************************************
FAILED - RETRYING: Wait until pyxis pod starts to run (300 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (299 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (298 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (297 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (296 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (295 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (294 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (293 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (292 retries left).
FAILED - RETRYING: Wait until pyxis pod starts to run (291 retries left).
changed: [10.211.64.107] => {"attempts": 11, "changed": true, "cmd": "kubectl --kubeconfig=/etc/kubernetes/admin.conf get po --namespace=sky-firmament | grep firmament-pyxis", "delta": "0:00:00.172916", "end": "2017-10-20 21:36:54.492635", "rc": 0, "start": "2017-10-20 21:36:54.319719", "stderr": "", "stderr_lines": [], "stdout": "firmament-pyxis-9wnzk              1/1       Running   0          56s", "stdout_lines": ["firmament-pyxis-9wnzk              1/1       Running   0          56s"]}

PLAY RECAP ******************************************************************************************************************************
10.211.64.107              : ok=118  changed=97   unreachable=0    failed=0
10.211.64.109              : ok=11   changed=7    unreachable=0    failed=0
```

### Verify
```sh
[root@kube07 ansible-ecp]# kubectl get po --all-namespaces
NAMESPACE       NAME                                             READY     STATUS    RESTARTS   AGE
kube-system     calico-etcd-h006t                                1/1       Running   0          11m
kube-system     calico-node-3pcxs                                2/2       Running   0          11m
kube-system     calico-node-70p77                                2/2       Running   1          9m
kube-system     calico-policy-controller-336633499-w1xws         1/1       Running   0          11m
kube-system     etcd-kube07                                      1/1       Running   0          11m
kube-system     helm-rudder-1209115447-c745p                     1/1       Running   0          7m
kube-system     kube-api-exporter-1890998689-l5q4b               1/1       Running   0          7m
kube-system     kube-apiserver-kube07                            1/1       Running   0          11m
kube-system     kube-controller-manager-kube07                   1/1       Running   0          11m
kube-system     kube-dns-95433198-p35k5                          3/3       Running   0          11m
kube-system     kube-proxy-5jmpv                                 1/1       Running   0          9m
kube-system     kube-proxy-krjwd                                 1/1       Running   0          11m
kube-system     kube-scheduler-kube07                            1/1       Running   0          10m
kube-system     kube-state-metrics-deployment-3043460491-9xp98   1/1       Running   0          7m
kube-system     kubernetes-dashboard-3313488171-xkstp            1/1       Running   0          9m
kube-system     river-4042643603-58fsr                           1/1       Running   0          7m
kube-system     tiller-deploy-3139936634-1tk1v                   1/1       Running   0          7m
sky-firmament   firmament-license-f1w3s                          1/1       Running   0          9m
sky-firmament   firmament-lyra-bq8xw                             1/1       Running   0          8m
sky-firmament   firmament-mysql-8s3hz                            1/1       Running   0          6m
sky-firmament   firmament-pyxis-9wnzk                            1/1       Running   0          4m
sky-firmament   grafana-core-3853529772-7mvbw                    1/1       Running   0          7m
sky-firmament   prometheus-core-1376599314-7whrt                 1/1       Running   0          7m
sky-firmament   prometheus-node-exporter-gg2r7                   1/1       Running   0          7m
sky-firmament   prometheus-node-exporter-s1dw4                   1/1       Running   0          7m
sky-firmament   skyform-sas-6xggb                                2/2       Running   0          5m

```

### Destroy
```sh
$ ansible-playbook reset-site.yml
```
