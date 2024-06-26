FROM ubuntu:latest
LABEL maintainer="mariogar1979@gmail.com"

ARG USER_ID
ARG GROUP_ID
ARG BUILD_DATE
ARG VERSION
ENV VERSION=${VERSION}

LABEL org.label-schema.build-date=$BUILD_DATE

USER root

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    iputils-ping \
    net-tools \
    iproute2 \
    traceroute \
    telnet \
    whois \
    ipcalc \
    tmux \
    mtr \
    pwgen \
    jq \
    sudo \
    procps \
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
    mysql-client \
    postgresql-client \
    python3-pip \
    ansible && \
    rm -rf /var/lib/apt/lists/*

# Atualiza o motd
COPY update-motd.sh /usr/local/bin/update-motd.sh

RUN chmod +x /usr/local/bin/update-motd.sh

RUN echo "/usr/local/bin/update-motd.sh" >> /etc/bash.bashrc 
RUN echo $VERSION > /etc/version 

# Remover o usuário ubuntu
RUN userdel -r ubuntu

# Verificar se o grupo com o GID especificado já existe
RUN getent group devops || groupadd --gid ${GROUP_ID} devops

# Criar um usuário devops dentro do contêiner com o userid do usuário local e pertencente ao grupo devops
RUN useradd --gid ${GROUP_ID} --uid ${USER_ID} --create-home --home /tools --shell /bin/bash devops

# Adicionar o usuário ao grupo sudo (opcional)
RUN usermod -aG sudo devops

RUN echo 'devops ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Instalação de ferramentas relacionadas ao Kubernetes
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep browser_download_url \
    | grep linux_amd64.deb \
    | cut -d '"' -f 4 \
    | wget -qi - && \
    dpkg -i k9s_linux_amd64.deb && \
    rm -rf k9s_linux_amd64.deb && \
    curl -s https://api.github.com/repos/astefanutti/kubebox/releases/latest \
    | grep browser_download_url \
    | grep linux \
    | cut -d '"' -f 4 \
    | wget -qi - -O kubebox-linux && \
    install -o root -g root -m 0755 kubebox-linux /usr/local/bin/kubebox && \
    curl -LO https://github.com/pulumi/kubespy/releases/download/v0.6.3/kubespy-v0.6.3-linux-amd64.tar.gz && \
    tar xzvf kubespy-v0.6.3-linux-amd64.tar.gz && \
    install -o root -g root -m 0755 kubespy /usr/local/bin && \
    rm -rf kubespy-v0.6.3-linux-amd64.tar.gz kubebox-linux kubectl kubespy

# Instalação de outras ferramentas
RUN curl -LO "https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz" && \
    tar xzvf helm-v3.7.0-linux-amd64.tar.gz && \
    install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin && \
    rm -rf helm-v3.7.0-linux-amd64.tar.gz linux-amd64 && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_amd64.tar.gz" && \
    tar xzvf eksctl_linux_amd64.tar.gz && \
    install -o root -g root -m 0755 eksctl /usr/local/bin && \
    rm -rf eksctl_linux_amd64.tar.gz eksctl && \
    curl -LO https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz && \
    tar xzvf doctl-1.104.0-linux-amd64.tar.gz && \
    install -o root -g root -m 0755 doctl /usr/local/bin && \
    rm -rf doctl-1.104.0-linux-amd64.tar.gz doctl && \
    curl -LO "https://downloads.rclone.org/v1.56.0/rclone-v1.56.0-linux-amd64.zip" && \
    unzip rclone-v1.56.0-linux-amd64.zip && \
    install -o root -g root -m 0755 rclone-v1.56.0-linux-amd64/rclone /usr/local/bin && \
    rm -rf rclone-v1.56.0-linux-amd64.zip rclone-v1.56.0-linux-amd64 && \
    curl -LO "https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip" && \
    unzip terraform_1.0.8_linux_amd64.zip && \
    install -o root -g root -m 0755 terraform /usr/local/bin && \
    rm -rf terraform_1.0.8_linux_amd64.zip terraform && \
    curl -LO "https://releases.hashicorp.com/vault/1.7.3/vault_1.7.3_linux_amd64.zip" && \
    unzip vault_1.7.3_linux_amd64.zip && \
    install -o root -g root -m 0755 vault /usr/local/bin && \
    rm -rf vault_1.7.3_linux_amd64.zip vault

    RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh && \
    chmod +x /tmp/install-opentofu.sh && \
    /tmp/install-opentofu.sh --install-method deb && \
    rm -rf /tmp/install-opentofu.sh && \
    curl -LO "https://dl.min.io/client/mc/release/linux-amd64/mc" && \
    install -o root -g root -m 0755 mc /usr/local/bin && \
    rm -rf mc && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    curl -LO https://aka.ms/downloadazcopy-v10-linux && \
    tar xzvf downloadazcopy-v10-linux && \
    install -o root -g root -m 0755 azcopy_linux_amd64_10.25.1/azcopy /usr/local/bin && \
    rm -rf downloadazcopy-v10-linux azcopy_linux_amd64_10.25.1

COPY entrypoint.sh /tmp/entrypoint.sh

COPY src/backup.py /tmp/backup.py

RUN chmod +x /tmp/entrypoint.sh && \
    mv /tmp/entrypoint.sh /entrypoint.sh && \
    install -o root -g root -m 0755 /tmp/backup.py /usr/local/bin/backup && \
    rm -rf backup 

# Remove os Downloads
RUN rm -rf /tmp/*

# Mapeia o diretório de trabalho localmente
VOLUME /tools

# Define o usuário padrão para o container
USER devops

WORKDIR /tools

ENTRYPOINT [ "/entrypoint.sh" ]
