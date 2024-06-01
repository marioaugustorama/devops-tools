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

