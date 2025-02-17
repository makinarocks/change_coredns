#!/bin/bash
set -e

# 1. 사용자로부터 IP 주소 입력받기
read -p "사용할 IP 주소를 입력하세요 (예: 192.168.2.53): " INPUT_IP

# 2. runway-ingress-gateway에서 RUNWAY_HOST 값 추출
RUNWAY_HOST=$(kubectl get gateway runway-ingress-gateway -n istio-system -o jsonpath='{.spec.servers[0].hosts[0]}')
echo "RUNWAY_HOST: $RUNWAY_HOST"

# 3. 추가할 hosts 블록 생성 (들여쓰기 포함)
NEW_HOSTS_BLOCK=$(cat <<EOF
    hosts {
      ${INPUT_IP} harbor.${RUNWAY_HOST} mlflow.${RUNWAY_HOST}
      
      fallthrough
    }
EOF
)
echo "추가할 hosts 블록:"
echo "${NEW_HOSTS_BLOCK}"

# 4. 현재 Corefile 가져오기
CURRENT_COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')

# 5. 기존에 동일 hosts 항목이 존재하는지 확인 (harbor.RUNWAY_HOST 문자열 존재 여부로 판단)
if echo "$CURRENT_COREFILE" | grep -q "harbor\.${RUNWAY_HOST}"; then
    echo "이미 동일한 hosts 블록이 존재합니다. 패치를 건너뜁니다."
    exit 0
fi

# 6. "loadbalance" 라인 바로 다음에 새로운 hosts 블록 추가
NEW_COREFILE=$(echo "$CURRENT_COREFILE" | awk -v block="$NEW_HOSTS_BLOCK" '
  /loadbalance/ {print; print block; next} 1
')
echo "패치 후 Corefile:"
echo "$NEW_COREFILE"

# 7. JSON patch에 사용하기 위해 새 Corefile 내용을 이스케이프 처리 (Python 활용)
ESCAPED_COREFILE=$(printf "%s" "$NEW_COREFILE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

# 8. kubectl patch 명령어로 ConfigMap 업데이트
kubectl patch configmap coredns -n kube-system --type=merge -p "{\"data\": {\"Corefile\": ${ESCAPED_COREFILE}}}"

# 9. CoreDNS Deployment 롤아웃 재시작
kubectl rollout restart deployment coredns -n kube-system
echo "CoreDNS Deployment가 재시작되었습니다."
