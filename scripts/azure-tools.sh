#!/bin/bash

curl -sL https://aka.ms/InstallAzureCLIDeb | bash
curl -LO https://aka.ms/downloadazcopy-v10-linux
tar xzvf downloadazcopy-v10-linux
install -o root -g root -m 0755 azcopy_linux_amd64_10.26.0/azcopy /usr/local/bin
rm -rf downloadazcopy-v10-linux azcopy_linux_amd64_10.26.0