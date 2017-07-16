version: '2'
services:
  host-subnet:
    privileged: true
    image: niusmallnan/rancher-host-subnet:v0.0.1
    command: sh -c "touch /var/log/rancher-cni.log && exec tail ---disable-inotify -F /var/log/rancher-cni.log"
    network_mode: host
    pid: host
    volumes:
    - /var/lib/rancher/host_subnet:/var/lib/cni/networks
    labels:
      io.rancher.network.cni.binary: 'rancher-bridge'
      io.rancher.container.dns: 'true'
      io.rancher.scheduler.global: 'true'
      io.rancher.network.tag_traffic: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    network_driver:
      name: Rancher Host Subnet
      default_network:
        name: host-subnet
        host_ports: true
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
