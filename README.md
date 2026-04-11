# DevOps - Tools

A distribuição foi projetada para atender às necessidades de profissionais e estudantes de DevOps e Networking, oferecendo uma seleção abrangente e atualizada das melhores ferramentas disponíveis no mercado. Ao reunir todas essas ferramentas em um único local, a distribuição visa agilizar o processo de configuração e implantação de ambientes DevOps. Isso elimina a necessidade de procurar e instalar cada ferramenta individualmente, proporcionando conveniência e economizando tempo. Com uma variedade de ferramentas essenciais já integradas e prontas para uso, os usuários podem começar a trabalhar rapidamente em seus projetos DevOps, aumentando sua produtividade e eficiência.

## Makefile (build/push/run)

Alvos principais:
- `make build [TAG=vX.Y.Z]` cria a imagem `marioaugustorama/devops-tools:<TAG>` (usa rede host). Variáveis úteis: `IMAGE`, `TAG`, `APT_MIRROR`, `APT_SECURITY_MIRROR`, `STRICT_CHECKSUM=0|1`, `BUILD_OPTS="--network=host"`.
- `make security-scan [TAG=...]` executa scan Trivy (HIGH/CRITICAL por padrão).
- `make security-gate [TAG=...]` igual ao scan, mas falha (`exit 1`) quando encontra vulnerabilidades.
- `make push [TAG=...]` publica a imagem atual.
- `make tag-latest` marca a imagem atual como `latest` e envia.
- `make run [TAG=...]` sobe o container via `run.sh` com `IMAGE/TAG` definidos.
- `make compose-up [TAG=...]` sobe o modo daemon com `docker compose up -d`.
- `make compose-up-vpn [TAG=...]` sobe o daemon com capacidade de VPN (`NET_ADMIN` + `/dev/net/tun`).
- `make compose-shell` abre shell no container daemon.
- `make compose-down` para/remove o container daemon.
- Bumps de versão: `make bump-patch|bump-minor|bump-major` (atualizam `version` via `scripts/version.sh`).
- Auxiliares: `make build-br` (espelho BR), `make build-insecure` (sem checksum estrito), `make version` (mostra versão), `make clean` (limpa cache Docker).

Exemplos rápidos:
```bash
# Build com tag atual do arquivo version
make build
# Build com mirror BR e tag específica
make build TAG=v1.18.5 APT_MIRROR=http://br.archive.ubuntu.com/ubuntu
# Publicar a tag e marcar latest
make push TAG=v1.18.5
make tag-latest TAG=v1.18.5
# Rodar localmente a imagem recém-buildada
make run TAG=v1.18.5
# Rodar em modo daemon (compose)
make compose-up TAG=v1.18.5
# Rodar em modo daemon com VPN no container
make compose-up-vpn TAG=v1.18.5
make compose-shell
# Gate de segurança na imagem padrão
make security-gate TAG=v1.18.9-1
```


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
   - [Bitwarden CLI](https://bitwarden.com/help/cli/): Gestão de segredos via terminal (`bw`).
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

## Início Rápido

Para a rápida execução basta que seja executado o seguinte comando.

```
curl -LO https://raw.githubusercontent.com/marioaugustorama/devops-tools/main/run.sh && chmod +x run.sh
```

Será feito o download e dado permissão de execução ao script.

É requerido que já tenha o docker instalado em sua máquina.

Será criado um diretório nomeado como **home**, onde todo seu histórico do shell, tal como arquivos de configuração criados pelos programas serão armazenados.

Portanto o máximo de cuidado com esse diretório, recomendo até que seja um volume criptografado com o Luks, nas futuras versão já virá com o software que prepara esse ambiente automaticamente.

### Modos de inicialização

Use o modo conforme o seu cenário:

- `run.sh` (interativo/efêmero): ideal para abrir uma sessão rápida e descartar o container ao sair.
- `docker compose up -d` (daemon/persistente): ideal para manter o ambiente ativo e conectar por múltiplos terminais com `docker compose exec`.
- `docker compose -f compose.yaml -f compose.vpn.yaml up -d`: mesmo daemon, porém com suporte a VPN dentro do container.

#### 1) Daemon com Docker Compose (`up -d`)

Se preferir, gere o `.env` automaticamente antes de subir:

```bash
bin/init-compose-env
```

Suba o container em background:

```bash
export LOCAL_USER_ID="$(id -u)"
export LOCAL_GROUP_ID="$(id -g)"
export DOCKER_GID="$(stat -c %g /var/run/docker.sock 2>/dev/null || echo 0)"
export DEVOPS_TAG="$(cat version 2>/dev/null || echo latest)"
docker compose up -d
```

Acessar shell no container já iniciado:

```bash
docker compose exec devops-tools bash
```

Executar comando sem abrir shell:

```bash
docker compose exec devops-tools kubectl version --client
```

Executar em outros terminais (sessões paralelas):

```bash
docker compose exec devops-tools bash
docker compose exec devops-tools k9s
docker compose exec devops-tools tmux new -A -s ops
```

Observação sobre o modo daemon:
- O container sobe com `sleep infinity` para ficar estável.
- O banner (MOTD) mostra a URL local padrão do `tools-web` (`http://localhost:30000`).
- Para iniciar o serviço web manualmente: `docker compose exec -d devops-tools tools-web`
- Para habilitar VPN dentro do container no modo daemon, use `make compose-up-vpn` (ou `docker compose -f compose.yaml -f compose.vpn.yaml up -d`).

Usar com `docker context` (host remoto):

```bash
docker context use meu-contexto
docker compose up -d
docker compose exec devops-tools bash
```

Ou sem trocar o contexto global:

```bash
DOCKER_CONTEXT=meu-contexto docker compose up -d
DOCKER_CONTEXT=meu-contexto docker compose exec devops-tools bash
```

Trocar contexto Kubernetes dentro do container:

```bash
kubectl config get-contexts
kubectl config use-context <contexto>
```

Parar/remover o modo daemon:

```bash
docker compose down
```

#### 2) Interativo com `run.sh`

Mantém o fluxo existente:

```bash
./run.sh
```

Ou com comando direto:

```bash
./run.sh backup
```

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

#### Serviço web de utilidades (backup + pacotes)

Você pode subir um endpoint HTTP dentro do container para criar e baixar backups:

```bash
# Sobe o serviço em http://localhost:30000
./run.sh tools-web
```

Com token (recomendado):

```bash
TOOLS_WEB_TOKEN='troque-este-token' ./run.sh tools-web
```

Auto-start ao entrar no container:
- Por padrão, ao abrir shell interativo (`./run.sh` sem comando), o `tools-web` sobe em background automaticamente.
- Para desativar: `TOOLS_WEB_AUTOSTART=0 ./run.sh`
- Log padrão: `/var/log/tools-web.log` (configurável em `TOOLS_WEB_LOG`). Se não houver permissão, usa fallback em `/tools/.tools-web.log`
- Compatibilidade: `backup-web` e variáveis `BACKUP_WEB_*` continuam aceitas.

Endpoints principais:
- `GET /` interface web simples
- `POST /api/backup` executa backup
- `GET /api/backups` lista backups
- `GET /api/packages` lista pacotes disponíveis do `pkg_add` (grupo/default/status)
- `GET /api/backups/<arquivo>` faz download
- `GET /api/backups/<arquivo>/contents` lista o conteúdo do arquivo tar
- `DELETE /api/backups/<arquivo>` exclui backup

Variáveis úteis:
- `TOOLS_WEB_HOST` (ou `BACKUP_WEB_HOST`) padrão: `0.0.0.0`
- `TOOLS_WEB_PORT` (ou `BACKUP_WEB_PORT`) padrão: `30000`
- `TOOLS_WEB_TOKEN` (ou `BACKUP_WEB_TOKEN`) exige token em `X-Backup-Token` ou `Authorization: Bearer ...`
- `BACKUP_DIR` (padrão: `/backup`)
- `BACKUP_ARCHIVE_LIST_MAX_LINES` (padrão: `5000`, limite de linhas ao listar conteúdo)
- `BACKUP_ARCHIVE_LIST_TIMEOUT` (padrão: `20` segundos para leitura de conteúdo)

### Gerenciador de pacotes interno (`pkg_add`)

- Listar catálogo: `pkg_add list`
- Listar apenas instalados (persistidos): `pkg_add list --installed`
- Listar por grupo: `pkg_add list --group k8s`
- Listar grupos: `pkg_add groups`
- Grupo recomendado de base: `pkg_add install --group core`
- Ver status (instalado/pendente): `pkg_add status`
- Detalhar um pacote: `pkg_add info <nome>`
- Instalar tudo: `pkg_add install --all`
- Instalar por grupo: `pkg_add install --group iac` (aceita múltiplos: `--group cloud,k8s`)
- Instalar pacotes específicos: `pkg_add install kubectl helm doctl` (use `--force` para reinstalar)
- Desabilitar marcação de instalado (não desinstala): `pkg_add disable eksctl`

Nota de segurança (release de fixes `v1.18.9-1`):
- Alguns binários com maior incidência de CVEs de upstream Go passaram para modo on-demand no build padrão: `kubespy`, `kubectx`, `kubens`, `kubectl-tree` e `mc`.
- Eles continuam disponíveis normalmente via `pkg_add install <pacote>`.

Os pacotes são definidos em `scripts/packages.tsv` com 4 colunas:
- `name`, `description`, `group`, `default_install (0|1)`.
- O build padrão (`run_all.sh`) instala só os pacotes com `default_install=1`; os demais ficam sob demanda via `pkg_add`.
- Também é possível filtrar build por grupo com `RUN_ALL_GROUPS=...` e forçar tudo com `RUN_ALL_MODE=all`.
- O grupo `core` concentra ferramentas de uso diário (ex.: `docker`, `ipcalc`, `less`, `updatedb`).

### TUI (MVP com Textual)

A TUI é opcional e não substitui os comandos/shell existentes.

- Comando: `devops-tui`
- Stack: Python + Textual
- Telas do MVP:
  - `Home`: resumo do ambiente, checks de paths/binários e saúde do backup service
  - `Packages`: catálogo de `scripts/packages.tsv`, filtro e instalação via `pkg_add install <pacote>`
  - `Backups`: lista/criação/detalhes/exclusão de backups via `tools-web` (com fallback local)
  - `Logs`: painel central com saídas de ações executadas pela TUI

Execução dentro do container:

```bash
devops-tui
```

Execução no repositório local (fora do container):

```bash
pip3 install textual
bin/devops-tui
```

### SSH Connect (`ssh-connect`)

- Comando: `ssh-connect`
- Interface padrão: `textual`
- Fallback/alternativa: `curses` (`ssh-connect --ui curses`)
- Origem dos hosts: `~/.ssh/config`

Execução dentro do container:

```bash
ssh-connect
ssh-connect --ui curses
ssh-connect -f ~/.ssh/config -k ~/.ssh
```

#### Cache local de artefatos (modo offline/4G)
- Instaladores de binários (ex.: `helm`, `kubectl`, `terraform`, `opentofu`, `mongodb`) agora usam cache local persistente.
- Diretório padrão do cache: `/var/lib/devops-pkg/cache` (no host: `./pkg_state/cache` via volume do `run.sh`).
- Primeira instalação baixa e salva no cache; instalações seguintes reutilizam o artefato local.
- Variáveis:
  - `PKG_CACHE_DIR`: altera diretório do cache.
  - `PKG_CACHE_ENABLED=0`: desabilita cache e força download.

### Gestão de segredos com Bitwarden (`bw`)

Instalação (se não estiver presente):
```bash
pkg_add install bitwarden
```

Fluxo básico:
```bash
bw config server https://vault.bitwarden.com
bw login --apikey
bw unlock --raw
export BW_SESSION="<token-retornado>"
```

Helper para executar comando com segredo em variável sem salvar em arquivo:
```bash
secret-run DB_PASSWORD get password "meu-item" -- ./meu-script.sh
```

#### Auto-instalação na subida do container
- Arquivos persistentes (montados em `/var/lib/devops-pkg`, diretório `pkg_state/` no host): `pkg_state/auto-install.list` (pkg_add) e `pkg_state/apt-packages.list` (apt). Linhas em branco ou começando com `#` são ignoradas.
- Edite esses arquivos no host para listar apenas o que quer auto-instalar. Exemplos:
  - `pkg_state/auto-install.list`: `kubectl`, `helm`, `k9s`
  - `pkg_state/apt-packages.list`: `traceroute`, `nmap`
- Suba o container com `PKG_AUTO_RESTORE=1 ./run.sh ...` para aplicar essas listas automaticamente. Combine com `PKG_LAZY_INSTALL=0` se não quiser instalação sob demanda via `command_not_found`.

### Como adicionar um novo pacote

1. Criar o instalador em `scripts/<nome>.sh` (bash, `set -euo pipefail`, idempotente).
2. Adicionar o pacote ao manifesto `scripts/packages.tsv` com descrição, grupo e flag de default.
3. Opcional: testar no container com `pkg_add install <nome>` e confirmar que roda repetidamente sem falhar.
4. Atualizar a imagem ou rodar `run_all.sh` para incluir no build (se `default_install=1` ou usando `RUN_ALL_MODE=all`).

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

### VPN dentro do container (WireGuard + OpenVPN)

Pré-requisitos de runtime:
- Interativo: `./run.sh` já sobe com `NET_ADMIN` + `/dev/net/tun`.
- Daemon: use `make compose-up-vpn` (ou `docker compose -f compose.yaml -f compose.vpn.yaml up -d`).
- Se precisar forwarding/NAT: `ENABLE_WG_FORWARDING=1`.

Instalação dos clientes VPN (dentro do container):
```bash
pkg_add install wireguard-tools openvpn
```

Diretórios padrão:
- WireGuard: `/etc/wireguard` (host: `./vpn-configs`)
- OpenVPN: `/etc/openvpn` (coloque seus `.ovpn` ou `.conf`)
- Chaves WireGuard: `/etc/wireguard/keys` (host: `./wireguard-keys`)

Comando unificado `vpn`:
```bash
# perfis disponíveis
vpn list

# subir WireGuard (ex.: /etc/wireguard/wg0.conf)
vpn up wg0 --type wireguard

# subir OpenVPN (ex.: /etc/openvpn/client.ovpn)
vpn up client.ovpn --type openvpn

# status
vpn status

# derrubar conexão
vpn down --type wireguard
vpn down --type openvpn
```

Observações:
- `vpn up`/`vpn down` usam `sudo` automaticamente quando necessário.
- OpenVPN roda em background e grava log em `/var/log/openvpn-client.log`.

### Contextos por cliente dentro do container

Para separar kubeconfig, SSH, Docker config e perfis VPN por cliente, use o comando `client`.

Estrutura esperada:

```text
/tools/clients/<cliente>/
  .kube/config
  .ssh/config
  .ssh/known_hosts
  .docker/
  wireguard/
  openvpn/
  env.sh
  aliases.sh
  bin/
```

Fluxo básico:

```bash
# criar a estrutura base
client init acme

# remover um cliente inativo
client delete acme --force

# ativar o cliente na shell atual
client use acme

# ver cliente ativo
client current

# abrir uma nova shell já no contexto do cliente
client enter acme

# limpar o contexto atual
client clear
```

Ao ativar um cliente, o shell passa a usar:
- `KUBECONFIG=/tools/clients/<cliente>/.kube/config`
- `DOCKER_CONFIG=/tools/clients/<cliente>/.docker`
- `WG_DIR=/tools/clients/<cliente>/wireguard`
- `OVPN_DIR=/tools/clients/<cliente>/openvpn`
- `ssh`/`scp` com `-F /tools/clients/<cliente>/.ssh/config`
- `PWD=/tools/clients/<cliente>`

Notas:
- `env.sh` é carregado automaticamente no `client use`.
- `aliases.sh` é carregado automaticamente no `client use`.
- O prompt passa a mostrar `[client:<nome>]`.
- O diretório corrente da shell muda para o diretório do cliente.
- `client clear` sai do contexto e volta para o diretório base da sessão.
- `client delete <cliente> --force` remove um cliente inativo.
- Esta primeira versão isola contexto e sessão; não cria namespace de rede por cliente.
