#!/bin/bash

curl -LO "https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip"
unzip terraform_1.0.8_linux_amd64.zip
install -o root -g root -m 0755 terraform /usr/local/bin
rm -rf terraform_1.0.8_linux_amd64.zip terraform