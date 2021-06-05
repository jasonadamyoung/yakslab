#!/bin/bash
# set the context
export knamespace=${1:-kube-system}
export kcontext=`kubectl config current-context`

# extract the server line
echo "##    SERVER   ##"
kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$kcontext\")].cluster.server}"
echo -en "\n"

# decode the cert
echo "## CERTIFICATE ##"
kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$kcontext\")].cluster.certificate-authority-data}" | tr -d '"' | base64 --decode
echo -en "\n"

# get the secret
echo "## ADMIN TOKEN ##"
kubectl --namespace=$knamespace get secret $(kubectl -n $knamespace get secret | grep gitlab-admin | awk '{print $1}') -o json | jq -r '.data.token' | base64 --decode
echo -en "\n"
