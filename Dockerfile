FROM ubuntu:16.10
ENV KUBECTL_VERSION=v1.4.6

RUN apt-get update && \
  apt-get install -y bash vim jq parallel git ca-certificates --no-install-recommends && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*

ADD https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

ADD provisioners provisioners
RUN chmod -R +x provisioners

ENV DEPLOYMENT_DIR deployments
ENV SECRETS_DIR secrets
ENV CONFIGMAPS_DIR configmaps
ENV NS_DIR namespaces


CMD ["bash", "-c", "/provisioners/script-${PROV_TYPE}.sh"]
