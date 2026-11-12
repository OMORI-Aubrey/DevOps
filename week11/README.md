# 11주차 - 쿠버네티스 설정과 상태 점검

> 교안: 11. 쿠버네티스 설정과 상태 점검

## 학습 목표

- 설정을 이미지에서 분리해야 하는 이유를 설명한다.
- Secret이 암호화가 아니라 인코딩임을 알고 그 한계를 설명한다.
- ConfigMap/Secret을 만들어 Pod에 환경 변수로 주입한다.
- liveness/readiness probe를 설정하고 실패 시 동작을 관찰한다.
- get → describe → logs 트러블슈팅 루틴을 수행한다.

## 배운 내용

### 설정 분리

같은 이미지를 개발·테스트·운영에서 쓰고 설정만 바꾼다 (Build once, run anywhere / 12-factor app의 Config 원칙).

| 방법 | 값이 정해지는 시점 |
|---|---|
| 코드 기본값 | 코드 작성 |
| Dockerfile ENV | 이미지 빌드 |
| `docker run -e`, compose environment, `.env` | 컨테이너 실행 |
| ConfigMap / Secret | Pod 시작 |

무상태(Stateless): 설정은 ConfigMap/Secret, 데이터는 Redis, 로그는 표준 출력으로 두고 Pod 안에는 남기지 않는다. 그래서 Pod를 여러 개로 늘려도 방명록 글이 사라졌다 나타났다 하지 않는다.

### ConfigMap vs Secret

| | ConfigMap | Secret |
|---|---|---|
| 담는 것 | 일반 설정 (제목, 색, 호스트, 포트) | 비밀번호, 토큰, 키 |
| 작성 위치 | `data:` (spec 아님) | `stringData:` (평문) → 저장 시 `data:`에 base64 |
| 보안 | 없음 | base64 인코딩일 뿐, 암호화 아님 |

| | 하는 일 | 되돌리기 | 예 |
|---|---|---|---|
| 인코딩 | 표기 방식 바꾸기 | 누구나 가능 | base64 |
| 암호화 | 열쇠로 잠그기 | 열쇠가 있어야 가능 | HTTPS |
| 해시 | 지문 만들기 | 불가능 (비교만) | Git 커밋 ID |

### Pod에 설정 넣기

| | `envFrom` | `env` + `valueFrom` |
|---|---|---|
| 넣는 것 | data 전체 | 지정한 키 하나 |
| 변수 이름 | 키 이름 그대로 | `name:`으로 새로 지정 |
| 사용처 | 방명록 (deployment.yaml) | Redis (redis.yaml) |

환경 변수는 프로세스가 시작할 때 정해지므로, ConfigMap을 고쳐도 떠 있는 Pod는 옛 값을 쓴다. `kubectl rollout restart`로 Pod를 새로 띄워야 반영된다.

ConfigMap 값은 모두 문자열이어야 해서 `"6379"`, `"#16a34a"`처럼 따옴표로 감싼다 (`#` 뒤는 주석이 됨).

### 자원 제한

| | 의미 | 넘으면 |
|---|---|---|
| requests | 필요하다고 요청하는 양 (스케줄러가 노드 고를 때 참고) | |
| limits (memory) | 사용 상한 | OOM kill |
| limits (cpu) | 사용 상한 | 느려짐 (throttling) |

`100m` = 0.1코어, `64Mi` = 64 × 1024 × 1024 바이트

### 프로브

| | livenessProbe | readinessProbe |
|---|---|---|
| 질문 | 살아 있니? | 요청 받을 준비 됐니? |
| 방명록 경로 | `/healthz` (항상 200) | `/readyz` (Redis 안 되면 503) |
| 실패 시 | 컨테이너 재시작 (RESTARTS 증가) | 서비스 대상에서 제외 (READY 0/1, 재시작 없음) |

성공 기준은 응답 코드 200~399. `initialDelaySeconds`(첫 검사까지 대기), `periodSeconds`(간격), `failureThreshold`(연속 실패 횟수)로 조절한다. readiness가 있으면 롤링 업데이트 때 새 Pod가 `/readyz`를 통과한 뒤에야 요청을 받는다.

컴포즈 healthcheck는 상태를 표시하는 데 그치지만, 쿠버네티스는 결과에 따라 재시작하거나 트래픽을 끊는다.

## 실습 과정

### 1. ConfigMap, Secret, Redis 배포

```bash
$ kubectl apply -f k8s/configmap.yaml
$ kubectl apply -f k8s/secret.yaml
$ kubectl apply -f k8s/redis.yaml
$ kubectl apply -f k8s/deployment.yaml
$ kubectl get pods
```

### 2. Secret 읽어 보기

```bash
$ kubectl get secret guestbook-secret -o jsonpath='{.data.REDIS_PASSWORD}' | base64 -d; echo
devops1234
```

`kubectl get secret -o yaml`에는 `ZGV2b3BzMTIzNA==`처럼 보여서 잠긴 것 같지만, base64는 표기만 바꾼 것이라 `base64 -d` 한 번으로 원래 비밀번호가 그대로 나옵니다.
클러스터에 접근할 수 있는 사람은 누구나 읽을 수 있으므로 Secret만 믿으면 안 되고, `secret.yaml`은 `.gitignore`로 제외하고 `secret.yaml.example`만 올렸습니다.

### 3. ConfigMap만 바꿔서 제목과 색 변경

```bash
$ kubectl edit configmap guestbook-config     # APP_TITLE, THEME_COLOR 수정
$ kubectl rollout restart deployment guestbook
$ kubectl exec deploy/guestbook -- printenv APP_TITLE THEME_COLOR
InhaTC DevOps 방명록
#0054A6
```

이미지 재빌드도, 코드 수정도 없이 제목과 색이 바뀌었고 방명록 글은 Redis에 있어서 그대로 남았다.

### 4. readiness 실패

```bash
$ kubectl scale deployment redis --replicas=0
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
guestbook-6b748975cd-c6cr7   0/1     Running   0          41s
guestbook-6b748975cd-q65cd   0/1     Running   0          47s
$ kubectl scale deployment redis --replicas=1   # 복구
```

### 5. liveness 실패

```bash
$ kubectl patch deployment guestbook -p '...'   # livenessProbe 경로를 /devops로
$ kubectl get pods
NAME                         READY   STATUS        RESTARTS      AGE
guestbook-6b748975cd-2c9tx   1/1     Terminating   0             6s
guestbook-6b748975cd-gtqpp   1/1     Running       0             12s
guestbook-7468c9bb5d-7wt2r   0/1     Running       0             6s
guestbook-7468c9bb5d-99k8k   1/1     Running       3 (28s ago)   2m43s
guestbook-7468c9bb5d-9dcbd   1/1     Terminating   4 (10s ago)   2m51s
redis-57d7f66958-xkkg2       1/1     Running       0             3m13s
$ kubectl describe pod  guestbook-7468c9bb5d-7wt2r | grep -i "liveness probe failed"
  Warning  Unhealthy  7s (x2 over 12s)  kubelet            spec.containers{web}: Liveness probe failed: HTTP probe failed with statuscode: 404
$ kubectl apply -f k8s/deployment.yaml  # 원복
```

## 트러블슈팅 3단 루틴

1. `kubectl get pods`로 STATUS, READY, RESTARTS를 보고 어떤 종류의 문제인지 먼저 구분한다.
2. `kubectl describe pod <이름>`의 맨 아래 Events에서 쿠버네티스가 왜 실패했다고 기록했는지 확인한다. 이미지·설정 이름 오타, 프로브 실패는 대부분 여기서 끝난다.
3. 컨테이너는 떴는데 앱이 죽는다면 `kubectl logs <이름>`으로 앱 자체 에러를 본다. 계속 재시작 중이면 `--previous`로 죽기 직전 로그를 본다.

| 화면 | 의심할 것 |
|---|---|
| CreateContainerConfigError | ConfigMap/Secret 이름 오타 → describe |
| Running 0/1 | readiness 실패 (방명록은 Redis 연결) |
| RESTARTS 증가 | liveness 실패, 앱 오류, OOM |
| CrashLoopBackOff | logs --previous |

AI에 로그를 붙여 넣을 때는 printenv 결과나 비밀번호를 지우고 넣는다.

## 파일 설명

| 파일 | 설명 |
|---|---|
| guestbook/k8s/configmap.yaml | APP_TITLE, THEME_COLOR, REDIS_HOST, REDIS_PORT |
| guestbook/k8s/secret.yaml | REDIS_PASSWORD (`.gitignore`로 제외) |
| guestbook/k8s/secret.yaml.example | Secret 양식 (비밀번호 CHANGE_ME) |
| guestbook/k8s/redis.yaml | Redis Deployment + ClusterIP Service |
| guestbook/k8s/deployment.yaml | envFrom, resources, liveness/readiness probe 추가 |
| .gitignore | `guestbook/k8s/secret.yaml` 추가 |

## 느낀 점

base64로 암호화한 비밀번호가 명령어 하나로 바로 평문으로 보여지는 점에 놀랐다.
암호화과 보안의 중요성을 깨달아 앞으로 .gitignore를 적극 활용해야겠다.
