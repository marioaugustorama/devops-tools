# DevOps - Tools

A distribuição foi projetada para atender às necessidades de profissionais e estudantes de DevOps e Networking, oferecendo uma seleção abrangente e atualizada das melhores ferramentas disponíveis no mercado. Ao reunir todas essas ferramentas em um único local, a distribuição visa agilizar o processo de configuração e implantação de ambientes DevOps. Isso elimina a necessidade de procurar e instalar cada ferramenta individualmente, proporcionando conveniência e economizando tempo. Com uma variedade de ferramentas essenciais já integradas e prontas para uso, os usuários podem começar a trabalhar rapidamente em seus projetos DevOps, aumentando sua produtividade e eficiência.


## Ferramentas Disponíveis

1. **Kubernetes**
   - [Kubectl](https://kubernetes.io/pt-br/docs/tasks/tools/install-kubectl-linux/): Uma ferramenta de linha de comando para interagir com clusters Kubernetes.
   - [K9S](https://k9scli.io/): Uma interface de terminal para Kubernetes.
   - [Kubebox](https://github.com/astefanutti/kubebox): Uma ferramenta de linha de comando para visualizar e interagir com clusters Kubernetes.
   - [Kubespy](https://github.com/pulumi/kubespy): Uma ferramenta para monitorar eventos de recursos Kubernetes em tempo real.
   - [Helm](https://helm.sh/): Um gerenciador de pacotes para Kubernetes.
   - [Eksctl](https://eksctl.io/): Utilitário cli para criação e gerẽncia de cluster EKS na AWS.

2. **Hashicorp**
   - [Terraform](https://www.terraform.io/): Uma ferramenta para provisionamento de infraestrutura.
   - [Vault](https://www.vaultproject.io/): Uma ferramenta para gerenciamento de segredos e chaves de criptografia.

3. **Ansible**
   - [Ansible](https://www.ansible.com/) 
   - [Ansible Galaxy](https://galaxy.ansible.com/ui/)

4. **OpenTofu**
   - [OpenTofu](https://opentofu.org/): Uma ferramenta de automação para instalação e configuração de ferramentas.

5. **Providers**
   - [AWS Cli](https://aws.amazon.com/pt/cli/): Uma interface de linha de comando para AWS.
   - [Digital Ocean Cli](https://docs.digitalocean.com/reference/doctl/): Uma interface de linha de comando para DigitalOcean.
   - [Azure](https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli): Ferramenta para acesso aos serviços da Microsoft Azure!

6. **Utilitários**
   - [Rclone](https://rclone.org/): Uma ferramenta para sincronização de arquivos.
   - [Minio](https://min.io/): Um servidor de armazenamento de objetos de código aberto compatível com a API S3 da Amazon.
   - [AzCopy](https://learn.microsoft.com/pt-br/azure/storage/common/storage-use-azcopy-v10): Ferramenta para cópiar facilmente de/para blobs e conta de armazenamento na Azure

7. **Programas diversos** 
   - iputils-ping
   - net-tools 
   - iproute2 
   - traceroute
   - telnet
   - whois
   - [ipcalc](https://linux.die.net/man/1/ipcalc): Ferramenta para calculo de redes.
   - [tmux](https://github.com/tmux/tmux): Terminal Multiplexer
   - [mtr](https://linux.die.net/man/8/mtr): Ferramenta para diagnóstico de rede.
   - [pwgen](https://linux.die.net/man/1/pwgen): Gerador de senhas.
   - [jq](https://jqlang.github.io/jq/): Json Parser para linha de comando.
   - curl
   - wget
   - rsync
   - [aria2](https://aria2.github.io/): Ferramenta de Download, suporte a HTTP, HTTPS, FTP, SFTP, BitTorrent e Metalink
   - git
   - unzip
   - file
   - vim
   - mysql-client
   - postgresql-client

## [Inicio Rápido](#quick-start)

Para a rápida execução basta que seja executado o seguinte comando.

```
curl -LO https://raw.githubusercontent.com/marioaugustorama/devops-tools/main/run.sh && chmod +x run.sh
```

Será feito o download e dado permissão de execução ao script.

É requerido que já tenha o docker instalado em sua máquina.

Será criado um diretório nomeado como **home**, onde todo seu histórico do shell, tal como arquivos de configuração criados pelos programas serão armazenados.

Portanto o máximo de cuidado com esse diretório, recomendo até que seja um volume criptografado com o Luks, nas futuras versão já virá com o software que prepara esse ambiente automaticamente.

### [Scripts](#helpers)

Scripts adicionados a imagem para tarefas corriqueiras.

1. Backup 

Scripts para backup do profile:

Execução:

A partir do Host:

```
./run.sh backup
```

Vai gerar um backup com data e hora da execução, permitindo assim salvar seus dados e configurações gerados a partir do container.

### Gerenciador de pacotes interno (`pkg_add`)

- Listar catálogo: `pkg_add list`
- Listar apenas instalados (persistidos): `pkg_add list --installed`
- Ver status (instalado/pendente): `pkg_add status`
- Detalhar um pacote: `pkg_add info <nome>`
- Instalar tudo: `pkg_add install --all`
- Instalar pacotes específicos: `pkg_add install kubectl helm doctl` (use `--force` para reinstalar)
- Desabilitar marcação de instalado (não desinstala): `pkg_add disable eksctl`

Os pacotes são definidos em `scripts/packages.tsv` (nome + descrição) e cada instalador mora em `scripts/<nome>.sh`.

#### Auto-instalação na subida do container
- Arquivos persistentes (montados em `/var/lib/devops-pkg`, diretório `pkg_state/` no host): `pkg_state/auto-install.list` (pkg_add) e `pkg_state/apt-packages.list` (apt). Linhas em branco ou começando com `#` são ignoradas.
- Edite esses arquivos no host para listar apenas o que quer auto-instalar. Exemplos:
  - `pkg_state/auto-install.list`: `kubectl`, `helm`, `k9s`
  - `pkg_state/apt-packages.list`: `traceroute`, `nmap`
- Suba o container com `PKG_AUTO_RESTORE=1 ./run.sh ...` para aplicar essas listas automaticamente. Combine com `PKG_LAZY_INSTALL=0` se não quiser instalação sob demanda via `command_not_found`.

### Como adicionar um novo pacote

1. Criar o instalador em `scripts/<nome>.sh` (bash, `set -euo pipefail`, idempotente).
2. Adicionar o pacote ao manifesto `scripts/packages.tsv` com uma descrição curta.
3. Opcional: testar no container com `pkg_add install <nome>` e confirmar que roda repetidamente sem falhar.
4. Atualizar a imagem ou rodar `run_all.sh` para incluir no build.

#### Boilerplate para novo instalador (`scripts/exemplo.sh`)
```bash
#!/bin/bash
set -euo pipefail
source /usr/local/bin/utils.sh

APP_VERSION="1.2.3"
URL="https://exemplo.com/app-${APP_VERSION}-linux-amd64.tar.gz"
TMP="app.tar.gz"

echo "Baixando app ${APP_VERSION}..."
curl -fLs "$URL" -o "$TMP" || error_exit "download falhou"

echo "Extraindo..."
tar xzf "$TMP"

echo "Instalando..."
install -o root -g root -m 0755 app /usr/local/bin/app || error_exit "install falhou"

echo "Limpando..."
rm -rf "$TMP" app
```

#### Checklist de idempotência
- Evite falhar se já instalado (detectar binário/versão e sair cedo quando apropriado).
- Use `set -euo pipefail` e `error_exit` para mensagens claras.
- Limpe artefatos temporários mesmo em reexecuções (remova antes de extrair).
- Prefira URLs versionadas e validação (checksum) quando possível.

### Pacotes apt persistentes do dia a dia

Use o helper `pkg_apt` (estado em `pkg_state/apt-packages.list`, montado em `/var/lib/devops-pkg`):

- Adicionar pacote(s): `pkg_apt add traceroute nmap`
- Ver lista: `pkg_apt list`
- Remover: `pkg_apt remove nmap`
- Aplicar/instalar todos os listados: `pkg_apt apply` (automático no start do container)

Os pacotes listados serão reinstalados automaticamente quando o container subir novamente, sem rebuild da imagem.

### Habilitar manuais (`man`)
- Rode `sudo enable-docs` para remover a exclusão de documentação e instalar `man-db` + `manpages`.
- Depois teste com `man ls` ou `man vim`.

### Editor de hosts (`hosts-editor`)

- Adicionar entrada: `sudo hosts-editor add 127.0.0.1 meu.servico.local api.local`
- Remover host(s): `sudo hosts-editor remove meu.servico.local api.local`
- Listar atual: `hosts-editor list`
- Variáveis úteis: `HOSTS_FILE` para usar outro arquivo (ex.: `HOSTS_FILE=./home/hosts hosts-editor add ...`); use `--no-backup` para pular backup automático.
- Por padrão cria um `.bak` com timestamp ao lado do arquivo alterado; alterar `/etc/hosts` pede permissão (sudo).

### VPN dentro do container (WireGuard)
- Pacote: `wireguard-tools` no catálogo (`pkg_add install wireguard-tools` ou `pkg_apt add wireguard-tools`).
- Configs e chave: monte `./vpn-configs` em `/etc/wireguard` e use `./wireguard-keys` para guardar a chave fornecida pelo servidor (montado em `/etc/wireguard/keys`).
- Execução: `./run.sh` já adiciona `NET_ADMIN`, `/dev/net/tun` e monta os volumes acima. Se precisar rotear tráfego (NAT/forwarding), suba com `ENABLE_WG_FORWARDING=1 ./run.sh ...` para aplicar os sysctls.
- Uso dentro do container: `wg-quick up wg0` / `wg-quick down wg0` (conf com `PrivateKey = /etc/wireguard/keys/<arquivo>`).
