#!/bin/bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_amd64.tar.gz"
tar xzvf eksctl_linux_amd64.tar.gz
install -o root -g root -m 0755 eksctl /usr/local/bin
rm -rf eksctl_linux_amd64.tar.gz eksctl