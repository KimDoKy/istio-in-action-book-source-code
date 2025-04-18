kind create cluster --name myk8s --image kindest/node:v1.32.2 --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000 # Sample Application
    hostPort: 30000
  - containerPort: 30001 # Prometheus
    hostPort: 30001
  - containerPort: 30002 # Grafana
    hostPort: 30002
  - containerPort: 30003 # Kiali
    hostPort: 30003
  - containerPort: 30004 # Tracing
    hostPort: 30004
  - containerPort: 30005 # kube-ops-view
    hostPort: 30005
networking:
  podSubnet: 10.10.0.0/16
  serviceSubnet: 10.200.1.0/24
EOF
