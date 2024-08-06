#!/bin/bash
echo "Instalando Kubespy"
curl -LO https://github.com/pulumi/kubespy/releases/download/v0.6.3/kubespy-v0.6.3-linux-amd64.tar.gz
tar xzvf kubespy-v0.6.3-linux-amd64.tar.gz
install -o root -g root -m 0755 kubespy /usr/local/bin
rm -rf kubespy-v0.6.3-linux-amd64.tar.gz kubespy
