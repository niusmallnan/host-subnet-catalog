Rancher Host-Subnet Networking
=================================

### Requirements
1. Rancher v1.6.4+.
2. Prepare a number of subnets for hosts. Each host installed Rancher Agent will need a subnet assigned. There cannot be overlap between the subnets. Each subnet must be routable to any other subnet, normally it will be done by programming the switch.

### Deployments

#### Prepare a Rancher environment based on Host-Subnet

1. Add the new Host-Subnet networking catalog. In `Admin->Settings->Catalog->Add Catalog`, add the Host-Subnet networking catalog at: https://github.com/niusmallnan/host-subnet-catalog.git

2. Add a new environment template based on Cattle and the new Host-Subnet catalog. In `Environments->Manage Environments->Add Template`, add a new environment template. Update the network configuration to use Host-Subnet by:
    1. Disable `Rancher IPsec` (which is the default Rancher option for network)
    2. Enable `Rancher Host-Subnet`

3. Create a new environment based on previously created template.

4. Upgrade the `network-manager` service in the environment for the Host-Subnet feature. In `Stacks->Infrastructure`, there will be a stack named `network-services`, includes a service named `network-manager`. Click options for the `network-manager` service, then click `Upgrade`. Use `niusmallnan/network-manager:packet` for `Select Image` in the following dialog, then continue to upgrade.

#### Adding a host to Rancher environment
1. In `Infrastructure->Hosts->Add Host`, select `Custom`, take a note of the related `docker run` command. It will look like:
    ```
    sudo docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.5 http://172.31.5.93:8080/v1/scripts/04033066C0164CF25094:1483142400000:KQrf2wQfJtdKxLHYuprV6LfWuQ
    ```
2. For each host to be added in the environment, user must add a specific Host-Subnet label. The label key is `io.rancher.network.per_host_subnet.cidr`, and the value is host's subnet CIDR. User need to add an additional parameter for the label to the command in step 1.

   For example, for a host with subnet `192.168.100.0/24`, the additional parameter will be: `-e CATTLE_HOST_LABELS='io.rancher.network.per_host_subnet.cidr=192.168.100.0/24'`

   The final command will look like:
    ```
    sudo docker run -e CATTLE_HOST_LABELS='io.rancher.network.per_host_subnet.cidr=192.168.100.0/24'  --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.5 http://172.31.5.93:8080/v1/scripts/04033066C0164CF25094:1483142400000:KQrf2wQfJtdKxLHYuprV6LfWuQ
    ```

Done!

#### More

To learn more about the details of Host-Subnet, please refer to: [design.md](./docs/design.md)

For how to use Host-Subnet on AWS, please refer to: [aws.md](./docs/aws.md)

