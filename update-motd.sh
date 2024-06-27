#!/bin/bash

# Obter o IP da interface eth0 (ou substitua pela interface correta)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
VERSION=$(cat /etc/version)
echo "********************************************"
echo "* Bem-vindo ao DevOps tools: $VERSION	  *"
echo "* IP da interface eth0: $IP_ADDRESS	  *"
echo "********************************************"
