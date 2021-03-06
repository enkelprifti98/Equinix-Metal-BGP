# Equinix-Metal-BGP

## This project aims to make BGP setup easy for Equinix Metal customers. 

### NOTE: This BGP automation script currently works across Ubuntu / Debian / CentOS Linux distributions.

Here are the steps you need to follow:

1. Create an Equinix Metal Organization and Project if you don't have one. Inside the project, you need to enable BGP found in the top bar under the "IPs & Networks" tab. You will have two options for BGP, Local and Global. Local BGP is used to announce Equinix owned IP space such as Elastic IPs. Global BGP is used to announce your own IP space if you have your own ASN.
2. Once you have enabled BGP for your project, request Elastic IPs or bring your own IPs to the project.
3. Generate an account API token which will be used to enabled BGP for the instances that you deploy or have already deployed. You can do this by going to the upper right corner avatar, there is an "API keys" section there to generate your own API token.
4. Modify the `auth_token` variable at the top of the bash script so that it is set to your own API token.
5. Create an instance and simply paste the bash script in this repository into the user data field or you can just run the bash script in an already running instance.
6. Once the script has finished, you can now add Elastic IP addresses or your own IPs to the OS loopback interface so that the BIRD BGP speaker starts to announce them. Here's an example on how to add and delete IPs to the loopback interface:

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
NETWORK=147.75.255.255
ONBOOT=yes
```

Then run `ifup lo:0`.

Your IPs should now be reachable! You can also announce the same IPs from multiple instances by following the same steps.
