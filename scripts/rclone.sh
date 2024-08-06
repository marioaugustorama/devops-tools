#!/bin/bash

curl -LO "https://downloads.rclone.org/v1.56.0/rclone-v1.56.0-linux-amd64.zip"
unzip rclone-v1.56.0-linux-amd64.zip
install -o root -g root -m 0755 rclone-v1.56.0-linux-amd64/rclone /usr/local/bin
rm -rf rclone-v1.56.0-linux-amd64.zip rclone-v1.56.0-linux-amd64