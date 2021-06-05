#!/bin/bash
# set the context
export knamespace=${1:-gitlab}

# extract the server line
# https://docs.gitlab.com/charts/installation/deployment.html#initial-login
echo "##    GitLab Root Password   ##"
kubectl get secret $knamespace-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
echo -en "\n"
