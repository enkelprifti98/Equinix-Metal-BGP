# Equinix-Metal-BGP

## This project aims to make BGP setup easy for Equinix Metal customers. Here are the steps you need to follow:

1. Create an Equinix Metal Organization and Project if you don't have one. Inside the project, you need to enable BGP found in the top bar under the "IPs & Networks" tab. You will have two options for BGP, Local and Global. Local BGP is used to announce Equinix owned IP space such as Elastic IPs. Global BGP is used to announce your own IP space if you have your own ASN.
2. Once you have enabled BGP for your project, request Elastic IPs or bring your own IPs to the project.
3. Generate an account API token which will be used to enabled BGP for the instances that you deploy or have already deployed. You can do this by going to the upper right corner avatar, there is an "API keys" section there to generate your own API token.
4. Create an instance and simply past the bash script in this repository into the user data field or you can just run the bash script in an already running instance.
5. Once the script has finished, you can now add Elastic IP addresses or your own IPs to the OS loopback interface so that the BIRD BGP speaker starts to announce them. Here's an example on how to add and delete IPs to the loopback interface:

`ip addr add x.x.x.x/xx dev lo`

`ip addr del x.x.x.x/xx dev lo`

Note: The IPs added to the `lo` interface using the above command aren't persistent across reboots. If you want to make them persistent, you will need to modify the network configuration files for each respective operating system. You can find examples on network configuration files for persistence and info on requesting Elastic IPs [here](https://metal.equinix.com/developers/docs/networking/elastic-ips/).

Your IPs should now be reachable! You can also announce the same IPs from multiple instances by following the same steps.
