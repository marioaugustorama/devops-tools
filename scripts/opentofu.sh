#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define a URL para o script de instalação do OpenTofu
INSTALL_SCRIPT_URL="https://get.opentofu.org/install-opentofu.sh"
INSTALL_SCRIPT_PATH="/tmp/install-opentofu.sh"

# Baixa o script de instalação
echo "Baixando script de instalação do OpenTofu..."
curl --proto '=https' --tlsv1.2 -fsSL "$INSTALL_SCRIPT_URL" -o "$INSTALL_SCRIPT_PATH" || error_exit "Falha ao baixar o script de instalação do OpenTofu"

# Verifica se o script foi baixado corretamente
if [ ! -f "$INSTALL_SCRIPT_PATH" ]; then
    error_exit "O script de instalação $INSTALL_SCRIPT_PATH não foi encontrado."
fi

# Concede permissão de execução ao script
echo "Concedendo permissão de execução ao script de instalação..."
chmod +x "$INSTALL_SCRIPT_PATH" || error_exit "Falha ao conceder permissão de execução ao script de instalação"

# Executa o script de instalação
echo "Executando o script de instalação do OpenTofu..."
"$INSTALL_SCRIPT_PATH" --install-method deb || error_exit "Falha ao instalar o OpenTofu"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$INSTALL_SCRIPT_PATH" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do OpenTofu concluída com sucesso."
