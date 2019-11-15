SHELL := /bin/bash
CLUSTER_NAME=blue

KUBECONFIG=$(shell kind get kubeconfig-path --name='$(CLUSTER_NAME)')
export KUBECONFIG

.PHONY:cache_k8s build_images push_images init_k8s clean_k8s install_cni clean_all 

#BUILD STUFF

#KUBERNETES STUFF
cache_k8s:
	cat kind/cni/images | xargs -I {} docker pull {}

init_k8s: create_cluster load_images install_cni install_psp

create_cluster:
	kind create cluster --name=$(CLUSTER_NAME) --config=kind/configs/blue.yaml

clean_k8s:
	kind delete cluster --name=$(CLUSTER_NAME) || exit 0

install_cni:
	cat kind/cni/images | xargs -I {} kind load docker-image {} --name=$(CLUSTER_NAME)
	kind get nodes --name=$(CLUSTER_NAME) | xargs -n1 -I {} docker exec {} sysctl -w net.ipv4.conf.all.rp_filter=0
	kubectl apply -f kind/cni/canal.yaml


clean_all: clean_k8s
