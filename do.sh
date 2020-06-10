#!/bin/bash

if [ x"$#" !=  x"1" ]; then
	echo "$0 output_dir"
	exit
fi
output_dir=$1; shift

mkdir -p ${output_dir}/misc
oc -n openshift-cluster-version logs $(oc -n openshift-cluster-version get pod -o custom-columns=NAME:.metadata.name --no-headers) > ${output_dir}/misc/log.cvo

kubectl api-resources -o wide > ${output_dir}/misc/kubectl_api-resources_-o_wide

top_confdir=${output_dir}/misc/router_configs
mkdir -p ${top_confdir}

for pod in $(oc -n openshift-ingress get pod -o=custom-columns=NAME:.metadata.name --no-headers); do
	echo "=> ${pod}"
	pod_confdir=${top_confdir}/${pod}
	mkdir -p ${pod_confdir}
	#for file in $(oc -n openshift-ingress rsh ${pod} ls -1 | cat); do
	for file in $(kubectl -n openshift-ingress exec -it ${pod} ls); do
		_file=$(echo ${file} | tr '\r' '\n')
		echo "==> ${_file}"
		oc -n openshift-ingress rsh ${pod} cat "${_file}" > ${pod_confdir}/${_file}
	done
done

(time ./kubedump -d ${output_dir} -a) 2>&1 | tee ${output_dir}/misc/log.kubedump
