#!/bin/bash

IMAGE_NAME="marioaugustorama/devops-tools"
LATEST_TAG="latest"

USER_ID=$(id -u)
GROUP_ID=$(id -g)

run() {
    if [ ! -d "home" ]; then
        mkdir -p home
    fi

    if [ ! -d "backup" ]; then
        mkdir -p backup
    fi

    docker run -it --tty --rm \
        -u $USER_ID:$GROUP_ID \
        -v "$(pwd)/home:/tools" \
        -v "$(pwd)/backup:/backup" \
        -e LOCAL_USER_ID=$USER_ID \
        -e LOCAL_GROUP_ID=$GROUP_ID \
        $IMAGE_NAME:$LATEST_TAG "$@"
}

# Executar a função 'run'
run "$@"
