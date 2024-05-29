# Equinix-Metal-BGP

## This project configures BGP for Equinix Metal instances. 

### NOTE: This BGP configuration script currently works across the following Linux distributions:
* Ubuntu
* Debian
* CentOS
* AlmaLinux
* Rocky Linux
* Red Hat Enterprise Linux
* Alpine
  * Bash required: `apk add bash` or replace [#!/bin/bash](https://github.com/enkelprifti98/Equinix-Metal-BGP/blob/main/Equinix-Metal-BIRD-Setup.sh#L1) with `#!/bin/sh`

Here are the steps you need to follow:

1. Create an Equinix Metal Organization and a Project inside the Organization.
2. Enable BGP for the project.
   * The project BGP setting can be found on the left sidebar under the `Networking` section. When clicking the activate BGP button you will have two options, Local and Global.
       * Local BGP is used to announce Equinix owned IP space such as Elastic IPs.
       * Global BGP is used to announce your own IP space if you have your own ASN.
3. Request Elastic IPs or bring your own IPs.
   * If you are bringing your own IPs, make sure you have route objects defined in your IRR. Your subnets should appear under the Global IP ranges section of the project BGP configuration page.
4. Generate a Personal API token.
   * The API token will be used to enable BGP for the instances that you deploy or have already deployed. You can generate an API token by going to the upper right corner avatar, there is a "Personal API Keys" section there to generate your own API token.
5. Copy [this](https://raw.githubusercontent.com/enkelprifti98/Equinix-Metal-BGP/main/Equinix-Metal-BIRD-Setup.sh) bash script and modify the [`auth_token`](https://github.com/enkelprifti98/Equinix-Metal-BGP/blob/main/Equinix-Metal-BIRD-Setup.sh#L5) variable at the beginning so that it is set to your own API token.
6. Create an instance and paste the bash script into the user data field or you can just run the bash script in an already running instance.
   * Note: It is required to have the Layer 3 private IPv4 10.x.x.x management network assigned to the host interface for the BGP session to be established with the Equinix Metal Top of Rack router. BGP session traffic is not allowed over the the public IPv4 management network.
8. Once the script has finished, you can now add Elastic IP addresses or your own IPs to the OS loopback interface so that the BIRD BGP speaker starts to announce them. Here's an example on how to add and delete IPs to the loopback interface:

`ip addr add x.x.x.x/xx dev lo`

`ip addr del x.x.x.x/xx dev lo`

Note: The IPs added to the `lo` interface using the above command aren't persistent across reboots. If you want to make them persistent, you will need to modify the network configuration files for each respective operating system. You can find examples on network configuration files for persistence and info on requesting Elastic IPs [here](https://metal.equinix.com/developers/docs/networking/elastic-ips/). I have also added examples here:

Using a sample IP address of 147.75.255.255/32, the following configuration will make the IP address permanent on your server:

## Ubuntu/Debian
Add to /etc/network/interfaces:

```
auto lo:0
iface lo:0 inet static
    address 147.75.255.255
    netmask 255.255.255.255
```

Then run `ifup lo:0`.

## Ubuntu/Debian (netplan)
Add to /etc/netplan/00-elastic.yaml:

```
network:
  version: 2
  renderer: networkd
  ethernets:
    lo:
      addresses:
        - 127.0.0.1/8
        - 147.75.255.255/32
```
then either `sudo netplan try` or `sudo netplan apply`

## CentOS
Add to /etc/sysconfig/network-scripts/ifcfg-lo:0:

```
DEVICE="lo:0"
BOOTPROTO="static"
IPADDR=147.75.255.255
NETMASK=255.255.255.255
ONBOOT=yes
```

Then run `ifup lo:0`.

Your IPs should now be reachable! You can also announce the same IPs from multiple instances by following the same steps.

## Troubleshooting

If your BGP session is not able to be established, you can follow the following tips for troubleshooting.

1. Make sure that the Private IPv4 10.x.x.x Layer 3 management network is assigned to the host interface as BGP traffic with the Equinix Metal Top of Rack router is only allowed through that network. More specifically, BGP is only allowed with the host IP so if you have a larger subnet size such as a /29, only the first / host IP will be able to establish a BGP session with the Equinix Metal Top of Rack routers.
2. Check if the following static routes are added to the host OS route table: (The 10.x.x.x IP should match with your server's private IPv4 gateway address.)
   ```
   route 169.254.255.1/32 via 10.x.x.x;
   route 169.254.255.2/32 via 10.x.x.x;
   ```
   Here's a sample method for adding the static routes in bash:
   ```bash
   GATEWAY_IP=$(curl https://metadata.platformequinix.com/metadata | jq -r '.network.addresses[] | select(.public == false and .address_family == 4) | .gateway')
   PEERS=$(curl https://metadata.platformequinix.com/metadata | jq -r '.bgp_neighbors[0].peer_ips[]')
   for i in ${PEERS}; do
   ip route add ${i} via $GATEWAY_IP
   done
   ```
4. Ensure that you don't have any firewall rules that are blocking traffic through TCP port 179 which is used for BGP sessions.
5. Verify that you are not crossing the BGP maximum prefix limit. On the server BGP speaker side, you will see an error along the lines of "Maximum Number of Prefixes Reached". The default limit of maximum prefixes per server instance/neighbor on the Top of Rack switches/routers is 10 prefixes. The maximum prefixes limit can be increased by making a request to the Equinix Metal support team.
6. Multihop is required so check that you have it enabled for the BGP peer.
