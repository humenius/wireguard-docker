FROM ubuntu:eoan

# Install wireguard packges
RUN apt update && \
 apt install -y software-properties-common && \
 add-apt-repository --yes ppa:wireguard/wireguard && \
 apt update && \
 apt install -y --no-install-recommends wireguard-tools iptables iproute2 ifupdown iputils-ping nano net-tools procps && \
 echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
 apt install -y resolvconf && \
 apt clean

# Add main work dir to PATH
WORKDIR /scripts
ENV PATH="/scripts:${PATH}"

# Use iptables masquerade NAT rule
ENV IPTABLES_MASQ=1

# Copy scripts to containers
COPY install-module /scripts
COPY run /scripts
COPY genkeys /scripts
RUN chmod 755 /scripts/*

# Wirguard interface configs go in /etc/wireguard
VOLUME /etc/wireguard

# Normal behavior is just to run wireguard with existing configs
CMD ["run"]
