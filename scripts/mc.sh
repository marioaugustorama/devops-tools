#!/bin/bash

curl -LO "https://dl.min.io/client/mc/release/linux-amd64/mc"
install -o root -g root -m 0755 mc /usr/local/bin
rm -rf mc