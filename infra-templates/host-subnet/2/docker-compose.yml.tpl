version: '2'
services:
  routes-updater:
    privileged: true
    pid: host
    network_mode: host
    image: niusmallnan/routes-updater:dev
    command: routes-updater -p hostgw
    environment:
      RANCHER_DEBUG: '${RANCHER_DEBUG}'
      RANCHER_METADATA_ADDRESS: '${RANCHER_METADATA_ADDRESS}'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    labels:
      io.rancher.scheduler.global: 'true'
  per-host-subnet:
    privileged: true
    image: niusmallnan/rancher-host-subnet:v0.0.1
    command: sh -c "touch /var/log/rancher-cni.log && exec tail ---disable-inotify -F /var/log/rancher-cni.log"
    network_mode: host
    pid: host
    volumes:
    - /var/lib/rancher/per_host_subnet:/var/lib/cni/networks
    labels:
      io.rancher.network.cni.binary: 'rancher-bridge'
      io.rancher.container.dns: 'true'
      io.rancher.scheduler.global: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    network_driver:
      name: Rancher Host Subnet
      default_network:
        name: per-host-subnet
        host_ports: true
      cni_config:
        '10-per-host-subnet.conf':
          name: per-host-subnet-network
          type: rancher-bridge
          bridge: ${BRIDGE}
          bridgeSubnet: "__host_label__: io.rancher.network.per_host_subnet.subnet"
          isDebugLevel: ${RANCHER_DEBUG}
          logToFile: /var/log/rancher-cni.log
          isDefaultGateway: true
          hostNat: {{ .Values.HOST_NAT  }}
          hairpinMode: {{  .Values.RANCHER_HAIRPIN_MODE  }}
          promiscMode: {{ .Values.RANCHER_PROMISCUOUS_MODE  }}
          mtu: ${MTU}
          isPerHostSubnet: true
          ipam:
            type: rancher-host-local-ipam
            subnet: "__host_label__: io.rancher.network.per_host_subnet.subnet"
            rangeStart: "__host_label__: io.rancher.network.per_host_subnet.range_start"
            rangeEnd: "__host_label__: io.rancher.network.per_host_subnet.range_end"
            gateway: "__host_label__: io.rancher.network.per_host_subnet.gateway"
            isDebugLevel: ${RANCHER_DEBUG}
            logToFile: /var/log/rancher-cni.log
            routes:
            - dst: 169.254.169.250/32
