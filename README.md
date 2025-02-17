## 사용방법
스크립트를 파일(e.g. patch-coredns.sh)에 저장합니다.

실행 권한을 부여합니다.

```
chmod +x patch-coredns.sh
스크립트를 실행합니다.
```
```
./patch-coredns.sh
```
이 스크립트는 사용자가 입력한 IP와 runway-ingress-gateway에서 가져온 RUNWAY_HOST 값을 기반으로 새 hosts 블록을 생성하여 CoreDNS ConfigMap의 Corefile에 추가하고, patch 명령어를 통해 업데이트한 후 CoreDNS Deployment를 재시작합니다.
