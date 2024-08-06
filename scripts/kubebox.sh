#!/bin/bash
echo "Instalando Kubebox"
curl -s https://api.github.com/repos/astefanutti/kubebox/releases/latest | grep browser_download_url | grep linux | cut -d '"' -f 4 | wget -qi - -O kubebox-linux
install -o root -g root -m 0755 kubebox-linux /usr/local/bin/kubebox
rm -f kubebox-linux
