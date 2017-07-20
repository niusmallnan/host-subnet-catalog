Rancher Host-subnet Networking
=================================

#### About Host-subnet Networking
Rancher now has IPsec/VXLAN networking belongs to the Overlay model, although there is a good scalability, but the performance is not good.
Especially when it is running in the Cloud environment, since the VM networking may be already Overlay model, 
so there will be nested Overlay, which leads to greater performance loss.

Host-subnet network is to solve this problem, while taking full advantage of the Cloud environment itself.
Its main principle is that in each Agent node containers have a separate subnet, 
different hosts different subnet containers connected together in the Router through the route tables.
Because there is no Overlay loss, the network performance is extremely high in this case. 
![](https://ws3.sinaimg.cn/mw1024/006tKfTcly1fhoembsca6j31kw0xe427.jpg)

#### About host labels in host-subnet networking:

| Key                                       | Required | Sample         |
|       :---:                               | :----:|   :----:          |
| io.rancher.network.host_subnet.cidr       | true  | 192.168.100.0/24  |
| io.rancher.network.host_subnet.range_start| false | 192.168.100.20    |
| io.rancher.network.host_subnet.range_end  | false | 192.168.100.200   |
| io.rancher.network.host_subnet.gateway    | false | 192.168.100.1 <br /> It will be the first IP address in the subnet if not specified             |

#### About the cni config file for host-subnet networking:

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
