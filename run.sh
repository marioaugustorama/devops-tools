#!/bin/bash

IMAGE_NAME="marioaugustorama/devops-tools"
LATEST_TAG="latest"

USER_ID=$(id -u)
GROUP_ID=$(id -g)

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

    docker run -it --tty --rm \
        -u $USER_ID:$GROUP_ID \
        -v "$(pwd)/home:/tools" \
        -v "$(pwd)/backup:/backup" \
        -e LOCAL_USER_ID=$USER_ID \
        -e LOCAL_GROUP_ID=$GROUP_ID \
        $IMAGE_NAME:$LATEST_TAG "$@"
}

# Verificar se a opção de ajuda foi solicitada
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Executar a função 'run'
run "$@"
