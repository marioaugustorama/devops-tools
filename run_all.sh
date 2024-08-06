#!/bin/bash

# Diretório onde estão os scripts de cada projeto
SCRIPTS_DIR="/usr/local/scripts"

# Executa todos os scripts no diretório
for SCRIPT in "$SCRIPTS_DIR"/*.sh; do
  if [[ -x "$SCRIPT" ]]; then
    echo "Executando $SCRIPT..."
    bash "$SCRIPT"
  else
    echo "Arquivo $SCRIPT não é executável ou não é um script válido."
  fi
done

echo "Todos os scripts foram executados."
