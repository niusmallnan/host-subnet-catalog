Rancher Host-subnet Networking
=================================

#### About Host-subnet Networking
Rancher现在已有的IPsec/VXLAN网络都属于Overlay模型，虽然有很好的扩展性，但是性能比较一般。尤其是当运行在Cloud环境中，由于很多Cloud环境的VM已经是Overkay网络，所以Container之间再来一层Overlay会导致更大的性能损耗。
Host-subnet网络就是为了解决这个问题，同时充分利用Cloud环境本身的特性。它的主要原理是每个Agent节点容器拥有独立的Subnet，在VPC的Router中通过RouteTable方式，将不同主机不同subnet的容器连接在一起。由于没有Overlay的损耗，这种场景下网络性能极高。 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fho4hf5we6j31kw0y977x.jpg)

#### 环境准备(以AWS为例)
假定我们已经在AWS配置了VPC/Subnet/RouteTable，参考配置如下：

| Resource  | Name      | Setting       |
| :---:     | :----:    | :----:        |
| VPC       | vpc-xxxx  | 172.31.0.0/16 |
| Subnet    | subnet-xxx| 172.31.0.0/20 |
| RouteTable| rtb-xxxx  | 172.31.0.0/16 local <br /> 0.0.0.0/0 igw-xxxx|

在这个VPC和Subnet中创建三台虚拟机，一台运行Rancher Server，另外两台作为Rancher Agent节点。配置如下：

| VM            | Flavor    | Private IP    | Others|
| :---:         | :----:    | :----:        |:----: |
| Rancher Server| t2.small  | 172.31.5.93   ||
| Agent HostA   | t2.small  | 172.31.14.187 |host-subnet: 192.168.100.0/24|
| Agent HostB   | t2.small  | 172.31.10.112 |host-subnet: 192.168.101.0/24|

这里注意一步关键操作，由于AWS的安全机制原因需要将两台Agent Host的src/dst校验关闭，其他云根据自身情况而定： 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho07y2r0uj317k0bwdgo.jpg)

#### 安装过程
选择Rancher Server节点部署Rancher最新的稳定版本(现在是Rancher v1.6.4):
`sudo docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:stable`

在Rancher UI中添加Host-subnet networking的catalog，repo地址是https://github.com/niusmallnan/host-subnet-catalog.git： 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnz7awjioj31kw0eztah.jpg)

创建一个新的环境模版：
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzak3ygtj311o0fsaay.jpg)

修改网络配置为Host-subnet，Disbale IPsec，Enable Host-subnet，通常来说Host-subnet使用默认配置即可： 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzdlxdixj31kw0jvmz0.jpg)

基于新的模版创建一个新的环境： 
![](https://ws1.sinaimg.cn/mw1024/006tKfTcly1fhnzf3sfwhj319e0pqq3s.jpg)

更新环境中的network-manger版本，由于当前代码还未合并，所以需要指定一个定制版本（niusmallnan/network-manager:packet），未来合并之后，无需做此步： 
![](https://ws2.sinaimg.cn/mw1024/006tKfTcly1fho0bhwqvfj314i0um75d.jpg)

在新的环境中添加Agent节点，注意要加入对应的Host Label，Label key为`io.rancher.network.host_subnet.cidr`，以HostA为例： 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhnzi0weqwj31kw0oc41c.jpg)

由于我们设定HostA的host-subnet为192.168.100.0/24，HostB的host-subnet为192.168.101.0/24，所以VPC的RouteTable规则更新如下： 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fhnzmzasbsj30vi0jwab4.jpg)

部署完成 
![](https://ws4.sinaimg.cn/mw1024/006tKfTcly1fho0f23zroj30ug11odj5.jpg)

#### 参数说明
Host Label说明

| Key                                       | Required | Sample         |
|       :---:                               | :----:|   :----:          |
| io.rancher.network.host_subnet.cidr       | true  | 192.168.100.0/24  |
| io.rancher.network.host_subnet.range_start| false | 192.168.100.20    |
| io.rancher.network.host_subnet.range_end  | false | 192.168.100.200   |
| io.rancher.network.host_subnet.gateway    | false | 192.168.100.1 <br /> It will be the first IP address in the subnet if not specified             |

CNI配置说明 
下面是一份CNI CONFIG，当然你也可以在对应的compose文件中看到其内容：

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

为什么enable promiscMode同时disable hairpinMode ，参见：https://github.com/rancher/rancher/issues/9090
