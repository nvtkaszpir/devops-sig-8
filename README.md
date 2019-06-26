# About

Minimal example app for lab under devops-sigs-8.

# Quick howtos
## Creating k8s cluster using `kind`

linux (make sure you have docker installed already)
```shell

curl -Lo ./kind-linux-amd64 https://github.com/kubernetes-sigs/kind/releases/download/v0.4.0/kind-linux-amd64
chmod +x ./kind-linux-amd64
mkdir ~/bin
mv ./kind-linux-amd64 ~/bin/kind

kind create cluster
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
kubectl cluster-info
```
