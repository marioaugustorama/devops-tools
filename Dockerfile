FROM ubuntu:22.04

LABEL maintainer="mariogar1979@gmail.com"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG BUILD_DATE
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}

LABEL org.label-schema.build-date=$BUILD_DATE

# Evita instalar documentação/man; para reverter, usar unminimize
RUN cat <<'EOF' > /etc/dpkg/dpkg.cfg.d/01_nodoc
path-exclude=/usr/share/doc/*
path-exclude=/usr/share/man/*
path-exclude=/usr/share/groff/*
path-exclude=/usr/share/info/*
path-exclude=/usr/share/lintian/*
path-exclude=/usr/share/linda/*
path-exclude=/usr/share/locale/*
# Mantém locale pt_BR (gerado mais adiante)
path-include=/usr/share/locale/pt_BR*
path-include=/usr/share/locale/locale.alias
EOF

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

# Copia e configura os scripts de instalação
COPY scripts /usr/local/scripts
COPY run_all.sh /usr/local/bin
COPY utils.sh /usr/local/bin
COPY bin/pkg_add /usr/local/bin
COPY bin/pkg_apt /usr/local/bin
COPY bin/hosts-editor /usr/local/bin
COPY bin/enable-docs /usr/local/bin
RUN chmod +x /usr/local/scripts/*.sh /usr/local/bin/run_all.sh /usr/local/bin/pkg_add /usr/local/bin/pkg_apt /usr/local/bin/hosts-editor /usr/local/bin/enable-docs

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
