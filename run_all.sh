#!/bin/bash

# Diretório onde os scripts estão localizados
SCRIPT_DIR="/usr/local/scripts"

# Arquivo de log
LOG_FILE="/var/log/run_all.log"

# Função para registrar logs
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Início do script
log_message "Iniciando a execução dos scripts em $SCRIPT_DIR"

# Itera sobre todos os scripts .sh no diretório especificado
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -x "$script" ]; then
        log_message "Executando o script: $script"
        "$script"
        if [ $? -eq 0 ]; then
            log_message "Script $script executado com sucesso."
        else
            log_message "Erro ao executar o script $script."
        fi
    else
        log_message "O arquivo $script não é executável ou não existe."
    fi
done

# Fim do script
log_message "Execução dos scripts concluída."
