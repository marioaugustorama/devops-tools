#!/bin/bash

# Obter o IP da interface eth0 (ou substitua pela interface correta)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo "********************************************"
echo "* Bem-vindo ao DevOps tools		  *"
echo "* IP da interface eth0: $IP_ADDRESS	  *"
echo "********************************************"
