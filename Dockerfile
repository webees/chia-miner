# CHIA BUILD STEP
FROM python:3.9 AS chia_build

ARG BRANCH=latest
ARG COMMIT=""

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        lsb-release sudo

WORKDIR /chia-blockchain

RUN echo "cloning ${BRANCH}" && \
    git clone --branch ${BRANCH} --recurse-submodules=mozilla-ca https://github.com/Chia-Network/chia-blockchain.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "$COMMIT" ] && git checkout $COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh ./install.sh

# IMAGE BUILD
FROM python:3.9-slim

EXPOSE 8555 8444

ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="copy"
ENV service="node"
ENV plots_dir="/plots"
ENV farmer_address=
ENV farmer_port=
ENV testnet="false"
ENV TZ="Asia/Shanghai"
ENV upnp="true"
ENV log_to_file="false"
ENV healthcheck="true"

# Deprecated legacy options
ENV harvester="false"
ENV farmer="false"

#################################################
ENV log_level=INFO
ENV ca="/ca"
ENV full_node_address=
ENV pool_xch=
ENV farm_xch=
#################################################

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y tzdata curl nano && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY --from=chia_build /chia-blockchain /chia-blockchain

ENV PATH=/chia-blockchain/venv/bin:$PATH
WORKDIR /chia-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-start.sh
RUN chmod +x /usr/local/bin/docker-healthcheck.sh

#################################################
COPY bj.sh /usr/local/bin/
COPY hdd_stats.sh /usr/local/bin/
COPY farm_summary.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/bj.sh
RUN chmod +x /usr/local/bin/hdd_stats.sh
RUN chmod +x /usr/local/bin/farm_summary.sh
#################################################

HEALTHCHECK --interval=1m --timeout=10s --start-period=20m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]