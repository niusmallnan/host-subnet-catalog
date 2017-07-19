Rancher Host-subnet Networking
=================================

### Requirements
Need to prepare a number of hosts, and there should be a configurable router in your network infrastructure. 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fhp0cs3566j31260nm74p.jpg)

In order to run Rancher, Docker needs to be installed on the host.
Choose the appropriate version of Docker is very important, 
you can refer to the specific here: [supported-docker-versions](http://rancher.com/docs/rancher/v1.6/en/hosts/#supported-docker-versions)

### Deployments

#### Deploy Rancher
Assume that three hosts are used for deployment, one running Rancher Server and the other two as Rancher Agent nodes.

Deploy Rancher's latest stable version at Rancher Server node (now Rancher v1.6.4).

```
sudo docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:stable
```

#### Create a Rancher environment based on Host-subnet

In the Rancher UI, add Host-subnet networking catalog, repo address is [host-subnet-catalog](https://github.com/niusmallnan/host-subnet-catalog.git): 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnz7awjioj31kw0eztah.jpg)

Create a new environment template based on `Cattle` orchestration: 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzak3ygtj311o0fsaay.jpg)

Modify the network configuration for the Host-subnet(disable IPsec and enable Host-subnet). 
Normally use the default configuration: 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhp2j06qo5j31kw0ic0un.jpg)

Create a new environment based on the new template: 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzf3sfwhj319e0pqq3s.jpg)

Upgrade the network-manager version in the environment, here should use `niusmallnan/network-manager:packet`. 
On how to upgrade services, please refer to: [upgrading-services-in-the-ui](http://rancher.com/docs/rancher/v1.6/en/cattle/upgrading/#upgrading-services-in-the-ui) 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho0bhwqvfj314i0um75d.jpg)

#### Add the hosts and configure the router
Add an agent node to the environment.
Note that you need to add the corresponding host label, the label key is `io.rancher.network.host_subnet.cidr`.
Take HostA as an example: 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhnzi0weqwj31kw0oc41c.jpg) 
Each host is configured with different host-subnet, so when registering other hosts, you need to replace the value of label `io.rancher.network.host_subnet.cidr`.

Assume that we set host-subnet for HostA to 192.168.100.0/24, for HostB is 192.168.101.0/24, 
so the routing table rules in the router need to be manually updated:

```
......
ip route add 192.168.100.0/24 via <HostA-IP> dev <interface>
ip route add 192.168.101.0/24 via <HostB-IP> dev <interface>
......
```

#### Check the results
After the deployment is complete, you can see that all infrastructure services are normal. 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fho0f23zroj30ug11odj5.jpg)

### Running on AWS
Host-subnet can run on most public clouds, we just use the more popular AWS as a demo.

Here pay attention to one step key operation,
Due to the security mechanism of AWS, it is necessary to disable the src/dst check of all the agent hosts, and the other clouds are according to their own situation: 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho07y2r0uj317k0bwdgo.jpg)

Then you can follow the deployment steps described above.

Please note in AWS, VPC RouteTable needs to be updated as follow: 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzmzasbsj30vi0jwab4.jpg)

### Other Notes
About host labels in host-subnet networking:

| Key                                       | Required | Sample         |
|       :---:                               | :----:|   :----:          |
| io.rancher.network.host_subnet.cidr       | true  | 192.168.100.0/24  |
| io.rancher.network.host_subnet.range_start| false | 192.168.100.20    |
| io.rancher.network.host_subnet.range_end  | false | 192.168.100.200   |
| io.rancher.network.host_subnet.gateway    | false | 192.168.100.1 <br /> It will be the first IP address in the subnet if not specified             |

About the cni config file for host-subnet networking:

```
cni_config:
    '10-host-subnet.conf':
      name: host-subnet-network
      type: rancher-bridge
      bridge: docker0
      isDebugLevel: ${RANCHER_DEBUG}
      logToFile: /var/log/rancher-cni.log
      isDefaultGateway: true
      hostNat: {{ .Values.HOST_NAT  }}
      hairpinMode: {{  .Values.RANCHER_HAIRPIN_MODE  }}
      promiscMode: {{ .Values.RANCHER_PROMISCUOUS_MODE  }}
      mtu: ${MTU}
      ipam:
        type: rancher-host-local-ipam
        isDebugLevel: ${RANCHER_DEBUG}
        logToFile: /var/log/rancher-cni.log
        routes:
        - dst: 169.254.169.250/32
```

| Key       | Default| Description       |
| :---:     | :----: |   :----:          |
| hostNat   | true   | Generate MASQUERADE rules and DNAT rules for containers |
| mtu       | 1500   | Explicitly set MTU to the specified value|
| hairpinMode| false  | Set hairpin mode for interfaces on the bridge |
| promiscMode| true | Set promiscuous mode on the bridge |

Why do you need to enable promiscMode and disable hairpinMode? See a [reference](https://github.com/rancher/rancher/issues/9090)

To learn more about the details of Host-subnet, please refer to: [design.md](./docs/design.md)

