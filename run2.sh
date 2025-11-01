#!/bin/bash
set -euo pipefail

# Permite override via env: DEVOPS_IMAGE e DEVOPS_TAG
IMAGE_NAME=${DEVOPS_IMAGE:-marioaugustorama/devops-tools}
VERSION=$(cat version)
IMAGE_TAG=${DEVOPS_TAG:-$VERSION}

USER_ID=$(id -u)
GROUP_ID=$(id -g)
IP_BIND="0.0.0.0"
PORTS="30000-30005:30000-30005"


show_help() {
    echo "Uso: $0 [opções] [comando]"
    echo
    echo "Opções:"
    echo "  --help, -h             Mostrar esta mensagem de ajuda e sair"
    echo
    echo "Comandos:"
    echo "  Se nenhum comando for fornecido, um shell interativo (bash) será iniciado."
    echo "  Qualquer comando fornecido será executado dentro do container Docker."
    echo
    echo "Exemplos:"
    echo "  $0               Inicia um shell interativo (bash) dentro do container Docker."
    echo "  $0 backup        Executa o script backup dentro do container Docker."
}


run() {
    if [ ! -d "home" ]; then
        mkdir -p home
    fi

    if [ ! -d "backup" ]; then
        mkdir -p backup
    fi

    docker run --name devops-tools --privileged -it --tty --rm \
        -u $USER_ID:$GROUP_ID \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$(pwd)/home:/tools" \
        -v "$HOME/.kube:/tools/.kube:ro" \
        -v "$(pwd)/backup:/backup" \
        -v "$(pwd)/logs:/var/log" \
        -e LOCAL_USER_ID=$USER_ID \
        -e LOCAL_GROUP_ID=$GROUP_ID \
        -e APP_VERSION=$VERSION \
        -p $IP_BIND:$PORTS \
        $IMAGE_NAME:$IMAGE_TAG "$@"
}

# Verificar se a opção de ajuda foi solicitada (tolerante a ausência de args)
if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
    show_help
    exit 0
fi

# Executar a função 'run'
run "$@"
