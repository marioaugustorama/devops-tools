FROM ubuntu:22.04

LABEL maintainer="mariogar1979@gmail.com"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG BUILD_DATE
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}

LABEL org.label-schema.build-date=$BUILD_DATE

# Arch/Versions
ARG ARCH=amd64
ARG KUBECTL_VERSION=v1.34.1
ARG HELM_VERSION=v3.7.0
ARG DOCTL_VERSION=1.104.0
ARG RCLONE_VERSION=1.56.0
ARG TERRAFORM_VERSION=1.0.8
ARG VAULT_VERSION=1.7.3
ARG K9S_VERSION=v0.50.16
ARG KUBESPY_VERSION=v0.6.3

# APT mirrors (permite override no build)
ARG APT_MIRROR=http://archive.ubuntu.com/ubuntu
ARG APT_SECURITY_MIRROR=http://security.ubuntu.com/ubuntu

# Checagem de integridade (1=verifica, 0=ignora)
ARG STRICT_CHECKSUM=1

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR}|g; s|http://security.ubuntu.com/ubuntu|${APT_SECURITY_MIRROR}|g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    htop \
    locales \
    kubectx \
    build-essential \
    iputils-ping \
    net-tools \
    iproute2 \
    traceroute \
    telnet \
    bind9-dnsutils \
    whois \
    ipcalc \
    tmux \
    mtr \
    pwgen \
    jq \
    sudo \
    procps \
    psmisc \
    curl \
    wget \
    rsync \
    aria2 \
    git \
    unzip \
    file \
    vim \
    groff \
    mandoc \
    bmon \
    mysql-client \
    postgresql-client \
    python3-pip \
    sshfs \
    bash-completion \
    ansible && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN locale-gen pt_BR.UTF-8 && \
    update-locale LANG=pt_BR.UTF-8

# Definir variáveis de ambiente para o locale
ENV LANG=pt_BR.UTF-8
ENV LANGUAGE=pt_BR:pt
ENV LC_ALL=pt_BR.UTF-8

############################################################
# Atualiza o motd e bashrc (se arquivos existirem no contexto)
COPY update-motd.sh /usr/local/bin/update-motd.sh
COPY update_bashrc /usr/local/bin/update_bashrc
RUN chmod +x /usr/local/bin/update-motd.sh && \
    cat /usr/local/bin/update_bashrc >> /etc/bash.bashrc && \
    echo "/usr/local/bin/update-motd.sh" >> /etc/bash.bashrc && \
    echo $APP_VERSION > /etc/version

# Remover o usuário ubuntu (se existir)
RUN id -u ubuntu >/dev/null 2>&1 && userdel -r ubuntu || true

# Verificar se o grupo com o GID especificado já existe
RUN getent group devops || groupadd --gid ${GROUP_ID} devops

## Grupo docker (para acesso ao socket)
RUN getent group docker || groupadd docker

# Criar um usuário devops dentro do contêiner com o userid do usuário local e pertencente ao grupo devops
RUN useradd --gid ${GROUP_ID} --uid ${USER_ID} --create-home --home /tools --shell /bin/bash devops

# Adicionar o usuário devops ao grupo docker
RUN usermod -aG docker devops

# Adicionar o usuário ao grupo sudo (opcional)
RUN usermod -aG sudo devops

RUN echo 'devops ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Instalação de ferramentas relacionadas ao Kubernetes
WORKDIR /tmp

# kubectl (pinned + checksum)
RUN set -euo pipefail && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -O "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -O "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256" && \
    ( [[ "${STRICT_CHECKSUM}" = "1" ]] && echo "$(cat kubectl.sha256) kubectl" | sha256sum -c - || echo "[warn] skipping kubectl checksum verification" ) && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm -f kubectl kubectl.sha256 && \
    \
    # k9s (pinned + checksum)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" && \
    (curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o k9s_checksums.txt "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/checksums.txt" || true) && \
    (test -s k9s_checksums.txt && grep "k9s_Linux_${ARCH}.tar.gz" k9s_checksums.txt | sha256sum -c - || echo "[warn] skipping k9s checksum verification") && \
    tar xzf k9s.tar.gz && \
    install -o root -g root -m 0755 k9s /usr/local/bin/k9s && \
    rm -f k9s k9s.tar.gz k9s_checksums.txt && \
    # kubebox (latest binary; upstream does not provide easy checksums)
    curl -s https://api.github.com/repos/astefanutti/kubebox/releases/latest \
    | grep browser_download_url \
    | grep linux \
    | cut -d '"' -f 4 \
    | wget -qi - -O kubebox-linux && \
    install -o root -g root -m 0755 kubebox-linux /usr/local/bin/kubebox && \
    rm -f kubebox-linux && \
    # kubespy (pinned)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -O https://github.com/pulumi/kubespy/releases/download/${KUBESPY_VERSION}/kubespy-${KUBESPY_VERSION}-linux-amd64.tar.gz && \
    tar xzvf kubespy-${KUBESPY_VERSION}-linux-amd64.tar.gz && \
    install -o root -g root -m 0755 kubespy /usr/local/bin && \
    rm -f kubespy kubespy-${KUBESPY_VERSION}-linux-amd64.tar.gz && \
    rm -rf /tmp/*

# Instalação de outras ferramentas
RUN curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -O "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -O "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz.sha256sum" && \
    ( [[ "${STRICT_CHECKSUM}" = "1" ]] && echo "$(cat helm-${HELM_VERSION}-linux-${ARCH}.tar.gz.sha256sum) helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | sha256sum -c - || echo "[warn] skipping helm checksum verification" ) && \
    tar xzvf helm-${HELM_VERSION}-linux-${ARCH}.tar.gz && \
    install -o root -g root -m 0755 linux-${ARCH}/helm /usr/local/bin && \
    rm -rf linux-${ARCH} helm-${HELM_VERSION}-linux-${ARCH}.tar.gz* && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && rm -rf aws awscliv2.zip && \
    \
    # doctl (pinned; try to verify if checksums file exists)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o doctl.tar.gz "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz" && \
    (curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o doctl-checksums.txt "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-checksums.txt" || \
     curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o doctl-checksums.txt "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/checksums.txt" || true) && \
    (test -s doctl-checksums.txt && grep "doctl-${DOCTL_VERSION}-linux-amd64.tar.gz" doctl-checksums.txt | sha256sum -c - || echo "[warn] skipping doctl checksum verification") && \
    tar xzvf doctl.tar.gz && install -o root -g root -m 0755 doctl /usr/local/bin && rm -f doctl doctl.tar.gz doctl-checksums.txt && \
    \
    # rclone (pinned + checksum)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o rclone.zip "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o rclone-SHA256SUMS "https://downloads.rclone.org/v${RCLONE_VERSION}/SHA256SUMS" && \
    ( [[ "${STRICT_CHECKSUM}" = "1" ]] && grep "rclone-v${RCLONE_VERSION}-linux-amd64.zip" rclone-SHA256SUMS | sha256sum -c - || echo "[warn] skipping rclone checksum verification" ) && \
    unzip -q rclone.zip && install -o root -g root -m 0755 rclone-v${RCLONE_VERSION}-linux-amd64/rclone /usr/local/bin && rm -rf rclone.zip rclone-SHA256SUMS rclone-v${RCLONE_VERSION}-linux-amd64 && \
    # terraform (pinned + checksum)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o terraform_SHA256SUMS "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    ( [[ "${STRICT_CHECKSUM}" = "1" ]] && grep "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" terraform_SHA256SUMS | sha256sum -c - || echo "[warn] skipping terraform checksum verification" ) && \
    unzip -q terraform.zip && install -o root -g root -m 0755 terraform /usr/local/bin && rm -f terraform terraform.zip terraform_SHA256SUMS && \
    # vault (pinned + checksum)
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" && \
    curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 -o vault_SHA256SUMS "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS" && \
    ( [[ "${STRICT_CHECKSUM}" = "1" ]] && grep "vault_${VAULT_VERSION}_linux_amd64.zip" vault_SHA256SUMS | sha256sum -c - || echo "[warn] skipping vault checksum verification" ) && \
    unzip -q vault.zip && install -o root -g root -m 0755 vault /usr/local/bin && rm -f vault vault.zip vault_SHA256SUMS && \
    rm -rf /tmp/*

RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh && \
    chmod +x /tmp/install-opentofu.sh && \
    /tmp/install-opentofu.sh --install-method deb && \
    curl -fsSLO "https://dl.min.io/client/mc/release/linux-amd64/mc" && \
    install -o root -g root -m 0755 mc /usr/local/bin && \
    rm -rf /tmp/*

# Copia e configura os scripts de instalação
COPY scripts /usr/local/scripts
COPY run_all.sh /usr/local/bin
COPY utils.sh /usr/local/bin
COPY bin/pkg_add /usr/local/bin
RUN chmod +x /usr/local/scripts/*.sh /usr/local/bin/run_all.sh /usr/local/bin/pkg_add

# Executa todos os scripts de instalação
RUN /usr/local/bin/run_all.sh

COPY entrypoint.sh /tmp/entrypoint.sh

COPY src/backup.py /tmp/backup.py

RUN chmod +x /tmp/entrypoint.sh && \
    mv /tmp/entrypoint.sh /entrypoint.sh && \
    install -o root -g root -m 0755 /tmp/backup.py /usr/local/bin/backup && \
    rm -rf backup 

# Mapeia o diretório de trabalho localmente
VOLUME /tools

# Define o usuário padrão para o container
USER devops

WORKDIR /tools

ENTRYPOINT [ "/entrypoint.sh" ]
