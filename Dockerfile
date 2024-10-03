FROM ubuntu:latest
LABEL maintainer="mariogar1979@gmail.com"

ARG USER_ID
ARG GROUP_ID
ARG BUILD_DATE
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}

LABEL org.label-schema.build-date=$BUILD_DATE

USER root

RUN apt-get update && \
    apt-get install -y \
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
    rm -rf /var/lib/apt/lists/*

RUN locale-gen pt_BR.UTF-8 && \
    update-locale LANG=pt_BR.UTF-8

# Definir variáveis de ambiente para o locale
ENV LANG=pt_BR.UTF-8
ENV LANGUAGE=pt_BR:pt
ENV LC_ALL=pt_BR.UTF-8


# Atualiza o motd
COPY update-motd.sh /usr/local/bin/update-motd.sh
COPY update_bashrc /usr/local/bin/update_bashrc

RUN chmod +x /usr/local/bin/update-motd.sh

RUN cat /usr/local/bin/update_bashrc >> /etc/bash.bashrc
RUN echo "/usr/local/bin/update-motd.sh" >> /etc/bash.bashrc 
RUN echo $APP_VERSION > /etc/version 

# Remover o usuário ubuntu
RUN userdel -r ubuntu

# Verificar se o grupo com o GID especificado já existe
RUN getent group devops || groupadd --gid ${GROUP_ID} devops

# Criar um usuário devops dentro do contêiner com o userid do usuário local e pertencente ao grupo devops
RUN useradd --gid ${GROUP_ID} --uid ${USER_ID} --create-home --home /tools --shell /bin/bash devops

# Adicionar o usuário ao grupo sudo (opcional)
RUN usermod -aG sudo devops

RUN echo 'devops ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

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

# Remove os Downloads
RUN rm -rf /tmp/*

# Mapeia o diretório de trabalho localmente
VOLUME /tools

# Define o usuário padrão para o container
USER devops

WORKDIR /tools

ENTRYPOINT [ "/entrypoint.sh" ]
