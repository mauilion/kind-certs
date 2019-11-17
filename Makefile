SHELL:=/bin/bash

CLUSTER_NAME=10
KIND_10m=mauilion/node:v1.16.3-10m
.PHONY: kubeconfig kubeconfig-token kubeconfig-context init_k8s cache_k8s check_expiration renew_all clean_k8s clean_all 
help:
	echo "do other stuff"
#BUILD STUFF
build_image:
	docker build -f build/Dockerfile -t $(KIND_10m) build/
push_image:
	docker push $(KIND_10m)

#KUBERNETES STUFF
cache_k8s:
	cat kind/images | xargs -I {} docker pull {}

init_k8s: create_cluster load_images kubeconfig kubeconfig-token kubeconfig-context

load_images:
	cat kind/load_images | xargs -I {} kind load docker-image {} --name 10

kubeconfig:
	kind get kubeconfig --internal --name=10 > .kube/kubeconfig
	@echo "kubeconfig updated"

kubeconfig-token:
	kubectl create serviceaccount admin 2>/dev/null || true
	kubectl create clusterrolebinding admin --serviceaccount=default:admin --clusterrole=cluster-admin 2>/dev/null || true
	./lib/kube-functions.sh create-kubeconfig admin > .kube/kubeconfig-token
	@echo "kubeconfig-token updated"

kubeconfig-context:
	@kubectl config set-context cert --cluster=${CLUSTER_NAME} --user=kubernetes-admin
	@kubectl config set-context token --cluster=${CLUSTER_NAME} --user=admin

create_cluster:
	kind get clusters | grep -qa $(CLUSTER_NAME) \
	|| kind create cluster --name=$(CLUSTER_NAME) --config=kind/config/kind.yaml --image=$(KIND_10m)

check_expiration:
	@kind get nodes --name=$(CLUSTER_NAME) | grep control-plane | sort | xargs -I {} bash -c \
		'echo -e "----- NODE: {} -----\n# kubeadm alpha certs check-expiration" ;\
		docker exec -i {} /usr/bin/kadm alpha certs check-expiration'

check_pods:
	@kind get nodes --name=$(CLUSTER_NAME) | grep -v external-load-balancer | sort | xargs -I {} bash -ic \
		'echo -e "----- NODE: {} -----\n# crictl ps" ;\
		docker exec -i {} crictl ps'

apply_manifests:
	kubectl apply -f kind/manifests

renew_all:
	@kind get nodes --name=$(CLUSTER_NAME) | grep control-plane | sort | xargs -I {} bash -c \
		'echo -e "----- NODE: {} -----\n# kubeadm alpha certs renew all --config=/kind/kubeadm.conf" ;\
		docker exec -i {} /usr/bin/kadm alpha certs renew all --config=/kind/kubeadm.conf | sed  s/.*WARN.*//'

manifests_out:
	kind get nodes --name=${CLUSTER_NAME} | grep control-plane | sort | xargs -I {} bash -c \
		'echo -e "----- NODE: {} -----\n# mv /etc/kubernetes/manifests/* /tmp/" ;\
		docker exec -i {} bash -c "mv /etc/kubernetes/manifests/*.yaml /tmp/"'

manifests_in:
	kind get nodes --name=${CLUSTER_NAME} | grep control-plane | sort | xargs -I {} bash -c \
		'echo -e "----- NODE: {} -----\n# mv /tmp/*.yaml /etc/kubernetes/manifests/" ;\
		docker exec -i {} bash -c "mv /tmp/*.yaml /etc/kubernetes/manifests/"'

clean_k8s:
	kind delete cluster --name=$(CLUSTER_NAME) || exit 0

clean_all: clean_k8s
	rm .kube/*
