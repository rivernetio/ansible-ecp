# !/bin/sh
pod_name=`kubectl get pods --namespace=sky-firmament |grep firmament-pyxis|awk '{ print $1 }'`

echo $pod_name

kubectl delete pods $pod_name --namespace=sky-firmament
