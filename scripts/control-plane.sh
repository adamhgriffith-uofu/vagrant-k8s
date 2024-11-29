#!/bin/bash

# Enable strict mode:
set -euo pipefail

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~ Configure First Kubernetes Control Plane Node                                   ~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "Installing kubeadm and kubectl..."
dnf install -y kubeadm kubectl --disableexcludes=kubernetes

if [ ! -f /etc/kubernetes/admin.conf ]
then
    echo "Installing and configuring bash-completion..."
    dnf install -y bash-completion
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
fi

if [ ! -f /usr/local/bin/helm ]
then
    echo "Downloading and installing Helm v${HELM_VERSION}..."
    HELM_ARCH=amd64
    cd /tmp
    curl -L --fail --remote-name-all https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz.sha256sum
    mkdir -p /usr/local/share/helm
    tar xzvfC helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz /usr/local/share/helm
    ln -s /usr/local/share/helm/linux-${HELM_ARCH}/helm /usr/local/bin/helm
    rm helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz{,.sha256sum}
    cd ~
fi

echo "Creating the Kubeadm config file..."
cat << EOF > /tmp/kubeadm-config.yml
---
# INIT CONFIGURATION
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
certificateKey: '${KUBE_CERTIFICATE_KEY}'
localAPIEndpoint:
  advertiseAddress: '${KUBE_API_ENDPOINT}'
  bindPort: 6443
nodeRegistration:
  criSocket: 'unix:///var/run/crio/crio.sock'
  imagePullPolicy: IfNotPresent
  imagePullSerial: true
  name: '${HOSTNAME}'
  taints: null
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
---
# CLUSTER CONFIGURATION
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
apiServer: {}
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: '${KUBE_CLUSTER_NAME}'
controllerManager: {}
controlPlaneEndpoint: '${KUBE_API_ENDPOINT}:6443'
dns: {}
encryptionAlgorithm: ECDSA-P256
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
# kubernetesVersion: 'v${KUBE_VERSION}'
networking:
  dnsDomain: '${KUBE_CLUSTER_DNS_DOMAIN}'
  podSubnet: '${KUBE_CLUSTER_POD_CIDR}'
  serviceSubnet: '${KUBE_CLUSTER_SVC_CIDR}'
proxy: {}
scheduler: {}
---
# KUBEPROXY CONFIGURATION
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
bindAddress: '0.0.0.0'
bindAddressHardFail: false
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
  qps: 0
clusterCIDR: '${KUBE_CLUSTER_POD_CIDR}'
configSyncPeriod: 0s
conntrack:
  maxPerCore: null
  min: null
  tcpBeLiberal: false
  tcpCloseWaitTimeout: null
  tcpEstablishedTimeout: null
  udpStreamTimeout: 0s
  udpTimeout: 0s
detectLocal:
  bridgeInterface: ""
  interfaceNamePrefix: ""
detectLocalMode: ""
enableProfiling: false
healthzBindAddress: ""
hostnameOverride: ""
iptables:
  localhostNodePorts: null
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  strictARP: true
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
    text:
      infoBufferSize: "0"
  verbosity: 0
metricsBindAddress: ""
mode: ipvs
nftables:
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
nodePortAddresses: null
oomScoreAdj: null
portRange: ""
showHiddenMetricsForVersion: ""
winkernel:
  enableDSR: false
  forwardHealthCheckVip: false
  networkName: ""
  rootHnsEndpointName: ""
  sourceVip: ""
---
# KUBLET CONFIGURATION
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
  - '${KUBE_CLUSTER_DNS}'
clusterDomain: '${KUBE_CLUSTER_DNS_DOMAIN}'
containerRuntimeEndpoint: ""
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMaximumGCAge: 0s
imageMinimumGCAge: 0s
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
    text:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
EOF

if [ ! -f /etc/kubernetes/admin.conf ]
then
    echo "Initializing the Kubernetes cluster with Kubeadm and uploading certs for HA control-plane..."
    kubeadm config images pull
    kubeadm init --config=/tmp/kubeadm-config.yml --upload-certs
fi

HACK_BOOTSTRAP_PATH=/vagrant_work/bootstrap.token
if [ ! -f "${HACK_BOOTSTRAP_PATH}" ]
then
    echo "Generating bootstrap token..."
    KUBE_BOOTSTRAP_TOKEN=$(kubeadm token create)
    echo "TEMPORARY: Copying bootstrap token to /vagrant_work..."
    echo "${KUBE_BOOTSTRAP_TOKEN}" > "${HACK_BOOTSTRAP_PATH}"

    echo "Calculating CA key hash..."
    KUBE_CA_KEY_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
    
    echo "Creating portion of new cluster join config..."
    cat << EOF > /vagrant_work/join-config.yml.part
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: "${KUBE_API_ENDPOINT}:6443"
    token: "${KUBE_BOOTSTRAP_TOKEN}"
    caCertHashes:
      - "sha256:${KUBE_CA_KEY_HASH}"
    unsafeSkipCAVerification: false
  tlsBootstrapToken: "${KUBE_BOOTSTRAP_TOKEN}"
timeouts:
  controlPlaneComponentHealthCheck: 4m0s
  discovery: 5m0s
  etcdAPICall: 2m0s
  kubeletHealthCheck: 4m0s
  kubernetesAPICall: 1m0s
  tlsBootstrap: 5m0s
  upgradeManifests: 5m0s
EOF

fi

if [ ! -f "${HOME}/.kube/config" ]
then
    echo "Enabling kubectl access for root..."
    mkdir -p "${HOME}/.kube"
    cp -i /etc/kubernetes/admin.conf "${HOME}/.kube/config"
fi

HACK_KUBECONFIG_PATH=/vagrant_work/admin.conf
if [ ! -f "${HACK_KUBECONFIG_PATH}" ]
then
    echo "TEMPORARY: Copying kubeconfig (admin.conf) to /vagrant_work..."
    # TODO: Figure out why worker nodes are inappropriately needing a local copy of admin.conf.
    cp -i /etc/kubernetes/admin.conf "${HACK_KUBECONFIG_PATH}"
fi

if [ ! -f /usr/local/bin/cilium ]
then
    echo "Downloading and installing the latest Cilium client..."
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CILIUM_CLI_ARCH=amd64
    cd /tmp
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CILIUM_CLI_ARCH}.tar.gz.sha256sum
    tar xzvfC cilium-linux-${CILIUM_CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
    cd ~
    echo "Installing Cilium ${CILIUM_VERSION}..."
    /usr/local/bin/cilium install --version ${CILIUM_VERSION}
    echo "Sleeping 120 seconds to give Cilium a chance to start up..."
    sleep 120
fi

/usr/local/bin/cilium status
# /usr/local/bin/cilium connectivity test   ## Won't work because control-plane taint. Needs a worker node first
