# myk8s-control-plane 진입 후 설치 진행
docker exec -it myk8s-control-plane bash
-----------------------------------
# (옵션) 코드 파일들 마운트 확인
tree /istiobook/ -L 1
혹은
git clone ... /istiobook

# istioctl 설치
export ISTIOV=1.17.8
echo 'export ISTIOV=1.17.8' >> /root/.bashrc

curl -s -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIOV sh -
cp istio-$ISTIOV/bin/istioctl /usr/local/bin/istioctl
istioctl version --remote=false

# default 프로파일 컨트롤 플레인 배포
istioctl install --set profile=default -y

# 설치 확인 : istiod, istio-ingressgateway, crd 등
kubectl get istiooperators -n istio-system -o yaml
kubectl get all,svc,ep,sa,cm,secret,pdb -n istio-system
kubectl get cm -n istio-system istio -o yaml
kubectl get crd | grep istio.io | sort

# 보조 도구 설치
kubectl apply -f istio-$ISTIOV/samples/addons
kubectl get pod -n istio-system

# 빠져나오기
exit
-----------------------------------

# 실습을 위한 네임스페이스 설정
kubectl create ns istioinaction
kubectl label namespace istioinaction istio-injection=enabled
kubectl get ns --show-labels

# istio-ingressgateway 서비스 : NodePort 변경 및 nodeport 지정 변경 , externalTrafficPolicy 설정 (ClientIP 수집)
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30000}]}}'
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8443, "nodePort": 30005}]}}'
kubectl patch svc -n istio-system istio-ingressgateway -p '{"spec":{"externalTrafficPolicy": "Local"}}'
kubectl describe svc -n istio-system istio-ingressgateway

# NodePort 변경 및 nodeport 30001~30003으로 변경 : prometheus(30001), grafana(30002), kiali(30003), tracing(30004)
kubectl patch svc -n istio-system prometheus -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 30001}]}}'
kubectl patch svc -n istio-system grafana -p '{"spec": {"type": "NodePort", "ports": [{"port": 3000, "targetPort": 3000, "nodePort": 30002}]}}'
kubectl patch svc -n istio-system kiali -p '{"spec": {"type": "NodePort", "ports": [{"port": 20001, "targetPort": 20001, "nodePort": 30003}]}}'
kubectl patch svc -n istio-system tracing -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 16686, "nodePort": 30004}]}}'

# Prometheus 접속 : envoy, istio 메트릭 확인
open http://127.0.0.1:30001

# Grafana 접속
open http://127.0.0.1:30002

# Kiali 접속 1 : NodePort
open http://127.0.0.1:30003

# (옵션) Kiali 접속 2 : Port forward
kubectl port-forward deployment/kiali -n istio-system 20001:20001 &
open http://127.0.0.1:20001

# tracing 접속 : 예거 트레이싱 대시보드
open http://127.0.0.1:30004


# 접속 테스트용 netshoot 파드 생성
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["tail"]
    args: ["-f", "/dev/null"]
  terminationGracePeriodSeconds: 0
EOF
