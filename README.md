Rancher Host-subnet Networking
=================================

#### About Host-subnet Networking
Rancher now has IPsec/VXLAN networking belongs to the Overlay model, although there is a good scalability, but the performance is not good.
Especially when it is running in the Cloud environment, since the VM networking may be already Overlay model, 
so there will be nested Overlay, which leads to greater performance loss.

Host-subnet network is to solve this problem, while taking full advantage of the Cloud environment itself.
Its main principle is that in each Agent node containers have a separate subnet, different hosts different subnet containers connected together in the VPC Router through the route tables.
Because there is no Overlay loss, this scene under the network performance is extremely high. 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fho4hf5we6j31kw0y977x.jpg)

#### Requirements(AWS Example)
Assuming we have configured the VPC / Subnet / RouteTable in AWS, the reference configuration is as follows:

| Resource  | Name      | Setting       |
| :---:     | :----:    | :----:        |
| VPC       | vpc-xxxx  | 172.31.0.0/16 |
| Subnet    | subnet-xxx| 172.31.0.0/20 |
| RouteTable| rtb-xxxx  | 172.31.0.0/16 local <br /> 0.0.0.0/0 igw-xxxx|

Create three VMs in this VPC and Subnet, one running Rancher Server and the other two as Rancher Agent nodes. The configuration is as follows:

| VM            | Flavor    | Private IP    | Others|
| :---:         | :----:    | :----:        |:----: |
| Rancher Server| t2.small  | 172.31.5.93   ||
| Agent HostA   | t2.small  | 172.31.14.187 |host-subnet: 192.168.100.0/24|
| Agent HostB   | t2.small  | 172.31.10.112 |host-subnet: 192.168.101.0/24|

Choose the appropriate version of Docker is very important, you can refer to the specific here:http://rancher.com/docs/rancher/v1.6/en/hosts/#supported-docker-versions

Here pay attention to one step key operation,
Due to the security mechanism of AWS, it is necessary to close the src / dst check of two Agent hosts, and the other clouds are according to their own situation: 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho07y2r0uj317k0bwdgo.jpg)

#### Deployment
Deploy Rancher's latest stable version at Rancher Server node (now Rancher v1.6.4) 
`sudo docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:stable`

In the Rancher UI, add Host-subnet networking catalog, repo address is https://github.com/niusmallnan/host-subnet-catalog.git: 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnz7awjioj31kw0eztah.jpg)

Create a new environment template: 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzak3ygtj311o0fsaay.jpg)

Modify the network configuration for the Host-subnet(disable IPsec and enable Vhost-subnet),
usually Host-subnet use the default configuration can be: 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzdlxdixj31kw0jvmz0.jpg)

Create a new environment based on the new template: 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzf3sfwhj319e0pqq3s.jpg)

Update the network-manager version in the environment, here should use `niusmallnan/network-manager:packet`: 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho0bhwqvfj314i0um75d.jpg)

Add an agent node to the environment.
Note that you need to add the corresponding host label, the label key is `io.rancher.network.host_subnet.cidr`.
Take HostA as an example: 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhnzi0weqwj31kw0oc41c.jpg)

Since we set host-subnet for HostA to 192.168.100.0/24, for HostB is 192.168.101.0/24, so the VPC RouteTable rules are updated as follows:
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzmzasbsj30vi0jwab4.jpg)

Deployment is complete 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fho0f23zroj30ug11odj5.jpg)

#### Other Notes
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
| hairpinMode| true  | Set hairpin mode for interfaces on the bridge |
| promiscMode| false | Set promiscuous mode on the bridge |

Why do you need to enable promiscMode and disable hairpinMode? See a reference：https://github.com/rancher/rancher/issues/9090
