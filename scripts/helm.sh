#!/bin/bash
echo "Instalando Helm"
curl -LO "https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz"
tar xzvf helm-v3.7.0-linux-amd64.tar.gz
install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin
rm -rf helm-v3.7.0-linux-amd64.tar.gz linux-amd64
