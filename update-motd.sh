#!/bin/bash

# Obter o IP da interface eth0 (ou substitua pela interface correta)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Atualizar o /etc/motd com o IP
echo "********************************************" > /etc/motd
echo "* Bem-vindo ao DevOps tools                *" >> /etc/motd
echo "* IP da interface eth0: $IPADDRESS         *" >> /etc/motd
echo "********************************************" >> /etc/motd
