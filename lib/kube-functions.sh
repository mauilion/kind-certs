function k8s_root () {
  kubectl run hack1 --restart=Never -t -i \
     --image overridden --overrides \
    '{
      "spec":{
        "hostPID": true,
        "nodeName": "'$1'",
        "containers":[{
          "name":"busybox",
          "image":"alpine",
          "command":[
            "nsenter",
            "--mount=/proc/1/ns/mnt",
            "--","/bin/bash"],
          "stdin": true,
          "tty":true,
          "securityContext":{
            "privileged":true
          }
        }]
      }
    }' --rm --attach
}

function create-kubeconfig() {
if [[ $# == 0 ]]; then
  echo "Usage: $0 SERVICEACCOUNT [kubectl options]" >&2
  echo "" >&2
  echo "This script creates a kubeconfig to access the apiserver with the specified serviceaccount and outputs it to stdout." >&2
  return 1
fi

serviceaccount="$1"
kubectl_options="${@:2}"

if ! secret="$(kubectl get serviceaccount $serviceaccount $kubectl_options -o 'jsonpath={.secrets[0].name}' 2>/dev/null)"; then
  echo "serviceaccounts \"$serviceaccount\" not found." >&2
  return 2
fi

if [[ -z "$secret" ]]; then
  echo "serviceaccounts \"$serviceaccount\" doesn't have a serviceaccount token." >&2
  return 2
fi

# context
context="$(kubectl config current-context)"
# cluster
cluster="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"$context\")].context.cluster}")"
server="$(kubectl config view -o "jsonpath={.clusters[?(@.name==\"$cluster\")].cluster.server}")"
# token
ca_crt_data="$(kubectl get secret $secret $kubectl_options -o "jsonpath={.data.ca\.crt}" | openssl enc -d -base64 -A)"
namespace="$(kubectl get secret $secret $kubectl_options -o "jsonpath={.data.namespace}" | openssl enc -d -base64 -A)"
token="$(kubectl get secret $secret $kubectl_options -o "jsonpath={.data.token}" | openssl enc -d -base64 -A)"

OLD_KUBECONFIG=$KUBECONFIG

export KUBECONFIG="$(mktemp)"
kubectl config set-credentials "$serviceaccount" --token="$token" >/dev/null
ca_crt="$(mktemp)"; echo "$ca_crt_data" > $ca_crt
kubectl config set-cluster "$cluster" --server="$server" --certificate-authority="$ca_crt" --embed-certs >/dev/null
kubectl config set-context "$context" --cluster="$cluster" --namespace="$namespace" --user="$serviceaccount" >/dev/null
kubectl config use-context "$context" >/dev/null

cat "$KUBECONFIG"
export KUBECONFIG=$OLD_KUBECONFIG
}

