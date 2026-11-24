# 13주차 - 깃옵스

> 교안: 13. 깃옵스

## 학습 목표

- GitOps("Git이 곧 진실")의 개념과 기존 배포 방식과의 차이를 설명한다.
- Argo CD로 Git 저장소와 클러스터를 동기화한다.
- 배포 전략(Recreate, Rolling, Blue/Green, Canary)과 A/B 테스트의 차이를 설명한다.
- 모니터링이 필요한 이유와 메트릭·로그·트레이스의 차이를 설명한다.
- `kubectl top`과 Grafana 대시보드에서 CPU/메모리 지표를 읽는다.

## 배운 내용

### CD와 GitOps

12주차까지는 CI가 이미지를 ghcr.io에 올려도 `kubectl set image`는 손으로 했다. 이번 주는 이 부분을 Argo CD로 자동화했다.

| | 푸시 방식 (CI가 직접 배포) | 풀 방식 (GitOps, Argo CD) |
|---|---|---|
| 클러스터를 바꾸는 주체 | 바깥의 CI 서버 | 클러스터 안의 Argo CD |
| 필요한 권한 | CI에 클러스터 접속 권한 | 바깥에 줄 권한 없음 |
| 방화벽 뒤 클러스터 | 접속 어려움 | 안에서 밖(GitHub)으로 나감 |
| 배포 기록 | 파이프라인 로그 따로 관리 | Git 히스토리 |
| 누가 손으로 수정하면 | 별도 감지 체계 필요 | 감지하고 되돌림 (selfHeal) |
| 되돌리기 | 이전 파이프라인 재실행 | `git revert` |

GitOps는 선언형의 완성이다. Deployment가 Pod 개수를 맞추듯, Argo CD는 Git(원하는 상태)과 클러스터(현재 상태)를 계속 비교하며 맞춘다.

| 용어 | 의미 |
|---|---|
| Sync | Git과 클러스터를 같게 맞추기 |
| Drift | 클러스터가 Git 선언에서 벗어난 상태 (급한 `kubectl edit`, 원복 잊음 등) |
| Prune | Git에서 지운 리소스를 클러스터에서도 삭제 |
| Self-heal | 손으로 바꾼 것을 Git 기준으로 되돌림 |

| Argo CD 화면 | 의미 |
|---|---|
| Synced / OutOfSync | 클러스터 = Git / 클러스터 ≠ Git |
| Healthy / Progressing / Degraded / Missing | 정상 / 교체 중 / Pod 문제 / Git에만 있음 |

Synced인데 Degraded면 Git대로 정확히 배포했지만 Git 내용이 틀린 것이다 (예: 없는 이미지 태그). 이때는 3단 루틴으로 원인을 찾는다.

CI가 이미지를 올리는 것만으로는 배포되지 않는다. Argo CD는 Git을 보므로 `deployment.yaml`의 `image:`를 새 태그로 바꾸는 PR을 머지해야 배포된다.

| | `kubectl rollout undo` | `git revert` + Argo CD |
|---|---|---|
| 되돌리는 곳 | 클러스터 직접 | Git (자동 반영) |
| 기록 | 클러스터 revision 번호 | 커밋 (누가, 언제, 왜) |
| selfHeal 켜져 있으면 | Git 상태로 다시 돌아감 | 그대로 유지 |

### 배포 전략

| 전략 | 비유 | 방식 | 감수할 것 |
|---|---|---|---|
| Recreate | 문 닫고 인테리어 | 옛 Pod 전부 내리고 새 Pod | 그 사이 서비스 중단 |
| RollingUpdate (기본) | 직원 한 명씩 교대 | 새 Pod 늘리고 옛 Pod 줄임 | 잠깐 두 버전 섞임 |
| Blue/Green | 옆에 새 매장 차리고 간판 교체 | v2를 다 띄우고 Service selector로 한 번에 전환 | 두 환경 유지 자원 |
| Canary | 손님 일부만 새 메뉴 | 일부에게 v2 → 지켜보며 늘림 | 지켜볼 모니터링 필요 |

| | Canary | A/B 테스트 |
|---|---|---|
| 묻는 것 | 새 버전은 안전한가? | 어느 쪽이 더 좋은가? |
| 보는 숫자 | 에러율, 응답 시간 | 클릭, 가입 등 비즈니스 지표 |
| 기간 | 몇 분~몇 시간 | 며칠~몇 주 |

A/B 테스트는 배포 전략이 아니라 배포 위에서 하는 실험이다.

### 모니터링

배포는 끝이 아니라 운영의 시작이다. 측정할 수 없으면 개선할 수 없다.

| 종류 | 무엇 | 도구 예 | 예 |
|---|---|---|---|
| 메트릭 | 시간에 따른 숫자 | Prometheus | CPU 80%, 요청 1200/초 |
| 로그 | 텍스트 기록 | Loki, ELK | ERROR: DB 연결 실패 |
| 트레이스 | 요청 하나의 여정 | Jaeger | 이 요청이 3초 걸린 이유 |

골든 시그널: 지연(얼마나 느린가), 트래픽(얼마나 많은가), 에러(얼마나 실패하나), 포화(자원이 얼마나 찼나)

- Prometheus: 앱의 `/metrics`를 주기적으로 가져가 저장 (Pull 방식, probe와 같은 원리)
- Grafana: 수집한 숫자를 대시보드로 시각화
- Alertmanager: 임계치를 넘으면 알림. 순간 튀는 값마다 울리면 아무도 안 보므로 "limit의 90%를 5분 넘게"처럼 조건을 둔다.

`kubectl top`의 `1m`은 1밀리코어(CPU 1개의 0.1%), `28Mi`는 약 30MB로, requests/limits와 비교해 여유를 판단한다.

## 실습 과정

### 1. Argo CD 설치와 애플리케이션 등록

```bash
$ kubectl create namespace argocd
$ kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
$ kubectl port-forward svc/argocd-server -n argocd 8443:443
$ kubectl apply -f argocd-application.yaml
$ kubectl get application -n argocd
NAME        SYNC STATUS   HEALTH STATUS
guestbook   Synced        Healthy
```

`argocd-application.yaml`은 저장소 루트에 두고 PR로 기록했다. `guestbook/k8s/` 안에 두면 Argo CD가 자기 설정까지 관리하게 된다.

### 2. Git으로 바꾸기 / 손으로 바꾸기

replicas 2 → 4로 바꾸는 PR을 머지하자 kubectl 없이 Pod가 4개로 늘었다. 이어서 손으로 10개로 바꿔 봤다.

```bash
$ kubectl scale deployment guestbook --replicas=10
$ kubectl get pods -w
```

Git에 4개라고 적혀 있어서 selfHeal이 되돌렸다. Git에 없는 변경은 인정되지 않는다. 그 뒤 `git revert`로 replicas 4 커밋을 되돌리는 PR을 머지해 2개로 복구했다.

### 3. prune

`guestbook/k8s/hello.yaml`(ConfigMap)을 추가하는 PR → 생성 확인 → 파일을 삭제하는 PR 머지

```bash
$ kubectl get cm hello
Error from server (NotFound): configmaps "hello" not found
```

클러스터에서 무언가를 지울 때도 `kubectl delete`가 아니라 Git에서 지운다.

### 4. 이미지 배포 (CI → GitOps)

1. 제목을 `CI/CD`로 바꾸는 코드 PR 머지 → Actions가 커밋 해시 태그 이미지 게시
2. `git rev-parse --short HEAD`로 태그 확인
3. `deployment.yaml`의 `image:`를 그 태그로 바꾸는 PR 머지
4. Argo CD가 감지해 롤링 업데이트 → 브라우저 제목이 바뀜

kubectl로 배포하지 않았고, 사람이 한 일은 코드 PR과 태그 PR 머지뿐이다. 머지 버튼이 곧 배포 승인이다.

### 5. 모니터링

```bash
$ minikube addons enable metrics-server
$ helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
$ kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
$ kubectl run load --image=busybox --restart=Never -- sh -c "while true; do wget -q -O /dev/null http://guestbook/; done"
$ kubectl top pods
$ kubectl delete pod load
```

Grafana의 Kubernetes / Compute Resources / Pod 대시보드에서 부하를 걸자 CPU 그래프가 requests 선을 넘어 올라갔다가, load Pod를 지우자 1~2분 뒤 내려갔다.

### 6. 정리

```bash
$ kubectl delete -f argocd-application.yaml
$ minikube stop
```

## 파일 설명

| 파일 | 설명 |
|---|---|
| argocd-application.yaml | Argo CD Application (guestbook/k8s → default, prune·selfHeal) |
| guestbook/k8s/deployment.yaml | image를 CI가 만든 커밋 해시 태그로 변경 |
| guestbook/templates/index.html | 제목 문구 `CI/CD`로 변경 |
| week13/README.md | 13주차 실습 기록 |

## 느낀 점

kubectl 명령 없이 PR 머지만으로 배포와 롤백이 되고, 손으로 바꾼 설정도 Argo CD가 Git 기준으로 되돌리는 것을 보면서
"Git이 곧 진실"이라는 말의 의미를 실감했다.
