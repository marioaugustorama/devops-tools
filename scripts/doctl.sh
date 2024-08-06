#!/bin/bash

curl -LO https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xzvf doctl-1.104.0-linux-amd64.tar.gz
install -o root -g root -m 0755 doctl /usr/local/bin
rm -rf doctl-1.104.0-linux-amd64.tar.gz doctl