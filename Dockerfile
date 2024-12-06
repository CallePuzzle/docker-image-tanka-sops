FROM debian:stable

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates git openssh-client \
    && apt-get clean
RUN wget https://github.com/getsops/sops/releases/download/v3.9.2/sops-v3.9.2.linux.arm64 -O /usr/local/bin/sops \
  && wget https://github.com/stedolan/jq/releases/download/jq-1.7.1/jq-linux-arm64 -O /usr/local/bin/jq \
  && wget https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_linux_arm64 -O /usr/local/bin/yq \
  && wget https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v0.6.0/jb-linux-arm64 -O /usr/local/bin/jb \
  && wget https://github.com/grafana/tanka/releases/download/v0.30.2/tk-linux-arm64 -O /usr/local/bin/tk \
  && chmod +x /usr/local/bin/*

RUN useradd -ms /bin/bash -u 999 tankasops
