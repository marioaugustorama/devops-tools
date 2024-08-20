#!/bin/bash

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

usermod -aG docker devops

chown $USER $GROUP /var/run/docker.sock
