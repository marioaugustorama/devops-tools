#!/bin/bash
curl -LO "https://releases.hashicorp.com/vault/1.7.3/vault_1.7.3_linux_amd64.zip"
unzip vault_1.7.3_linux_amd64.zip
install -o root -g root -m 0755 vault /usr/local/bin
rm -rf vault_1.7.3_linux_amd64.zip vault
