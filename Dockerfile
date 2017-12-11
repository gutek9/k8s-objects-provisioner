FROM  oberthur/docker-ubuntu:16.04

RUN apt-get update \
  && apt-get -y upgrade \
  &&  apt-get install -y bash curl vim jq parallel git ca-certificates --no-install-recommends && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*

COPY provisioners provisioners
RUN chmod -R +x provisioners

CMD ["bash", "-c", "/provisioners/provisioner.sh"]
