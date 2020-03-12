# wireguard-docker
Wireguard setup in Docker on Debian (or Ubuntu) kernel meant for a simple personal VPN.
There are currently 3 branches, `stretch`, `buster` or `ubuntu-eoan`. Use the branch that corresponds to your host machine if the kernel module install feature is going to be used.

## Overview
This docker image and configuration is my simple version of a wireguard personal VPN, used for the goal of security over insecure (public) networks, not necessarily for Internet anonymity. The docker images uses Ubuntu Eoan (19.10) stable, and the host OS must also use the Ubuntu stable kernel, since the image will build the wireguard kernel modules on first run. As such, the hosts /lib/modules directory also needs to be mounted to the container on the first run to install the module (see the Running section below). Thanks to [activeeos/wireguard-docker](https://github.com/activeeos/wireguard-docker) for the general structure of the docker image. It is the same concept just built on Ubuntu 16.04.

## Run
### First Run
If the wireguard kernel module is not already installed on the __host__ system, use this first run command to install it:
```
docker run -it --rm --cap-add sys_module -v /lib/modules:/lib/modules humenius/wireguard-docker:buster install-module
```

### Normal Run
```
docker run --cap-add net_admin --cap-add sys_module -v <config volume or host dir>:/etc/wireguard -p <externalport>:<dockerport>/udp humenius/wireguard-docker:buster
```
Example:
```
docker run --cap-add net_admin --cap-add sys_module -v wireguard_conf:/etc/wireguard -p 5555:5555/udp humenius/wireguard-docker:buster
```
### Generate Keys
This shortcut can be used to generate and display public/private key pairs to use for the server or clients
```
docker run -it --rm humenius/wireguard-docker:buster genkeys
```

## Configuration
Sample server configuration to go in /etc/wireguard:
```
[Interface]
Address = 192.168.20.1/24
PrivateKey = <server_private_key>
ListenPort = 5555

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 192.168.20.2
```
Sample client configuration:
```
[Interface]
Address = 192.168.20.2/24
PrivateKey = <client_private_key>
ListenPort = 0 #needed for some clients to accept the config

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_public_ip>:5555
AllowedIPs = 0.0.0.0/0,::/0 #makes sure ALL traffic routed through VPN
PersistentKeepalive = 25
```
## Other Notes
- This Docker image also has a iptables NAT (MASQUERADE) rule already configured to make traffic through the VPN to the Internet work. This can be disabled by setting the environment varialbe IPTABLES_MASQ to 0.
- For some clients (a GL.inet router in my case) you may have trouble with HTTPS (SSL/TLS) due to the MTU on the VPN. Ping and HTTP work fine but HTTPS does not for some sites. This can be fixed with [MSS Clamping](https://www.tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.cookbook.mtu-mss.html). This is simply a checkbox in the OpenWRT Firewall settings interface.
- This image can be used as a client as well. If you want to forward all traffic through the VPN (`AllowedIPs = 0.0.0.0/0`), you need to use the `--privileged` flag when running the container

## docker-compose
Sample docker-compose.yml
```
version: "2"
services:
 vpn:
  image: humenius/wireguard-docker:buster
  volumes:
   - data:/etc/wireguard
  networks:
   - net
  ports:
   - 5555:5555/udp
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
   - SYS_MODULE

networks:
  net:

volumes:
 data:
  driver: local
```
## Build
Since the images are already on Docker Hub, you only need to do this if you want to change something
```
git clone https://github.com/humenius/wireguard-docker.git
cd wireguard-docker
# For Debian, either use:
git checkout stretch 
##OR##
git checkout buster

# For Ubuntu, use:
git checkout ubuntu-eoan

docker build -t wireguard:local .
```
