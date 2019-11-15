#!/usr/bin/env bash

########################
# include the magic
########################
. lib/demo-magic.sh
. lib/kube-functions.sh

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# put your demo awesomeness here
#if [ ! -d "stuff" ]; then
#  pe "mkdir stuff"
#fi

#pe "cd stuff"

# show a prompt so as not to reveal our true nature after
# the demo has concluded
make clean_docker
make init_k8s
make join
kubectl create ns secure
kubectl create rolebinding secure-admin -n secure --clusterrole=admin --serviceaccount=secure:default
create-kubeconfig default -n secure > norm.kubeconfig

# hide the evidence
clear


# put your demo awesomeness here
#if [ ! -d "stuff" ]; then
#  pe "mkdir stuff"
#fi

#pe "cd stuff"
p  "we can deploy all the things we ran in docker as pods on Kubernetes"
pe "vim ./kind/manifests/dind-mount.yaml"
pe "vim ./kind/manifests/dind-priv.yaml"
pe "kubectl apply -f ./kind/manifests/dind-mount.yaml"
pe "kubectl apply -f ./kind/manifests/dind-priv.yaml"
pe "kubectl get pods -o wide"
kubectl exec dind-priv -- /import.sh >/dev/null
p  "we can still use them the same as well!"
pe "kubectl exec dind-priv -- docker run -d --rm quay.io/mauilion/dind:blue"
pe "pgrep -a true-blue"
pe "pstree -aps $(pgrep -o true-blue)"
p  "that is a mind boggling bunch of abstraction there!"
clear
p  "we probably don't want to allow users to run docker in docker unchecked"
p  "this is a job for admission control!"
p  "let's take a look at the available pod security policies"
pe "kubectl describe psp"
p  "Now let's try to deploy the dind-priv pod as a normal user"
pe "export KUBECONFIG=norm.kubeconfig"
pe "kubectl apply -n secure -f kind/manifests/dind-priv.yaml"
p  "nice! I also want to restrict hostpath mounts that would enable the"
p  "mount style dind pod to work"
pe "kubectl apply -n secure -f kind/manifests/dind-mount.yaml"
p  "we can still deploy reasonable things though! let's try nginx"
pe "kubectl create -n secure deployment nginx  --image=nginx:stable"
pe "kubectl scale -n secure deployment nginx --replicas=3"
pe "kubectl get pods -o wide -n secure"
p  "they are up!"
clear
p  "now for 1 tweet to root!"
. .envrc
pe "vim kind/manifests/r00t.yaml"
p  "let's use this to take over the node!"
pe "kubectl apply -f kind/manifests/r00t.yaml"
pe "kubectl get pod r00t -o wide"
pe "sudo touch /etc/flag"
pe "kubectl exec r00t -- nsenter -a -t 1 bash -c 'pstree -aps \$\$'"
pe "kubectl exec -it r00t -- nsenter -a -t 1 bash"
pe "sudo cat /etc/flag"
sudo rm /etc/flag
p  "this is why we want to limit what users or attackers can do"
p  "admission control!"
# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
