#!/bin/bash
echo "Instalando K9s"
curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep browser_download_url | grep linux_amd64.deb | cut -d '"' -f 4 | wget -qi -
dpkg -i k9s_linux_amd64.deb
rm -rf k9s_linux_amd64.deb
