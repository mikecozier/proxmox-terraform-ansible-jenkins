FROM jenkins/jenkins:lts

USER root
ARG TF_VERSION=1.9.8

RUN apt-get update && \
    apt-get install -y python3 python3-pip sshpass curl unzip jq && \
    pip3 install --break-system-packages ansible && \
    curl -fsSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" && \
    unzip -o /tmp/terraform.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform && \
    rm -rf /var/lib/apt/lists/* /tmp/*

USER jenkins

