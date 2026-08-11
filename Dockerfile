FROM debian:stable

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates git openssh-client \
    && apt-get clean
RUN wget https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.arm64 -O /usr/local/bin/sops \
  && wget https://github.com/stedolan/jq/releases/download/jq-1.8.2/jq-linux-arm64 -O /usr/local/bin/jq \
  && wget https://github.com/mikefarah/yq/releases/download/v4.53.3/yq_linux_arm64 -O /usr/local/bin/yq \
  && wget https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v0.6.0/jb-linux-arm64 -O /usr/local/bin/jb \
  && wget https://github.com/grafana/tanka/releases/download/v0.38.0/tk-linux-arm64 -O /usr/local/bin/tk \
  && chmod +x /usr/local/bin/*

RUN useradd -ms /bin/bash -u 999 tankasops
