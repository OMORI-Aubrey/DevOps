# 10주차 - 쿠버네티스 배포와 서비스 / 왜 굳이

> 교안: 09. 쿠버네티스 배포와 서비스, 10. 왜 굳이

## 학습 목표

- Deployment, ReplicaSet, Pod의 계층 관계를 설명한다.
- 서비스가 필요한 이유와 레이블·셀렉터로 오브젝트가 연결되는 원리를 설명한다.
- deployment.yaml, service.yaml을 작성하고 `kubectl apply`로 배포한다.
- 스케일링, 롤링 업데이트, 롤백을 수행하고 과정을 설명한다.
- 지금까지 쓴 도구(WSL, Git, 도커, 컴포즈, 쿠버네티스)가 각각 어떤 문제를 해결하는지 설명한다.

## 배운 내용

### 명령에서 파일로

| 구분 | 지난주 (명령형) | 이번 주 (선언형) |
|---|---|---|
| 만드는 법 | `kubectl create deployment ...` | `kubectl apply -f deployment.yaml` |
| 원하는 상태 저장 | 머릿속, 터미널 기록 | 파일 (Git으로 관리) |
| 무엇이 바뀌었나 | 기억에 의존 | `git diff`로 확인 |
| 다른 클러스터 재현 | 다시 하나하나 입력 | `apply -f` 한 번 |

| | create | apply |
|---|---|---|
| 의미 | 새로 만들어라 | 이 상태가 되게 해라 |
| 이미 있으면 | AlreadyExists 에러 | 차이만 반영 (없으면 unchanged) |

`apply`는 몇 번 실행해도 결과가 같다 (멱등성).

### Deployment → ReplicaSet → Pod

| 오브젝트 | 역할 | 누가 만드나 |
|---|---|---|
| Deployment | 버전, 개수, 교체 방법 선언 | 내가 YAML로 |
| ReplicaSet | Pod 개수 유지 | Deployment가 자동 생성 |
| Pod | 실제 컨테이너 실행 단위 | ReplicaSet이 template으로 찍어냄 |

template은 붕어빵 틀이고 Pod는 틀에서 찍은 붕어빵이다. Pod를 지우면 같은 틀로 다시 굽고(자가 치유), 틀이 바뀌면(이미지 v1 → v2) 새 틀로 구워서 교체한다(롤링 업데이트).

### YAML 4가지 필드

| 필드 | 의미 | 예 |
|---|---|---|
| apiVersion | 이 종류를 다루는 API 버전 | Deployment는 `apps/v1`, Service는 `v1` |
| kind | 무엇을 만들까 | Deployment, Service |
| metadata | 이름표 | `name: guestbook` |
| spec | 원하는 상태 | replicas, template / ports |

### 레이블과 셀렉터

레이블 `app: guestbook`이 세 곳에서 같아야 연결된다.

| 위치 | 틀렸을 때 |
|---|---|
| Deployment `selector.matchLabels` | apply 자체가 실패 |
| Deployment `template.metadata.labels` | apply 자체가 실패 |
| Service `selector` (matchLabels 없이 바로 작성) | 에러는 없는데 접속 안 됨 (Endpoints 비어 있음) |

### 서비스

Pod는 다시 만들어지면 IP가 바뀌므로, 고정된 이름과 IP를 가진 대표 창구가 필요하다. 서비스는 셀렉터로 찾은 Pod들에게 요청을 나눠 보낸다(로드밸런싱). 서비스 이름이 클러스터 안의 주소가 되어 다른 Pod에서 `http://guestbook`으로 접속할 수 있다.

| 포트 | 의미 | 이번 실습 |
|---|---|---|
| nodePort | 클러스터 바깥에서 들어오는 문 (30000~32767) | 30080 |
| port | 서비스의 문 | 80 |
| targetPort | 컨테이너의 문 (app.py가 듣는 곳) | 5000 |

| 타입 | 설명 | 언제 |
|---|---|---|
| ClusterIP | 클러스터 내부 전용 (기본값) | DB 등 |
| NodePort | 노드의 포트로 외부 노출 | 수업, 개발용 |
| LoadBalancer | 클라우드 로드밸런서 연결 | 실무 |

7주차와 비교하면, 컴포즈에서는 nginx 컨테이너와 nginx.conf를 직접 붙였지만 쿠버네티스는 Service 몇 줄로 레이블이 붙은 Pod를 자동으로 찾아 분배한다.

### 롤링 업데이트와 롤백

- 롤링 업데이트: 템플릿이 바뀌면 새 ReplicaSet이 생기고, 새 Pod를 하나 띄워 준비되면 옛 Pod를 하나 내리는 것을 반복한다. Ready 상태 Pod 수가 유지되므로 서비스가 (거의) 끊기지 않는다.
- 롤백: `rollout undo`는 0개로 남겨둔 이전 ReplicaSet을 다시 키운다. 코드를 되돌려 다시 빌드할 필요가 없다. 되돌려도 기록은 지워지지 않고 새 번호가 붙는다 (git revert와 비슷).

| 명령 | 하는 일 |
|---|---|
| `kubectl rollout status deployment/guestbook` | 교체 진행 상황 |
| `kubectl rollout history deployment/guestbook` | 버전(REVISION) 목록 |
| `kubectl rollout undo deployment/guestbook` | 바로 이전 버전으로 |
| `kubectl rollout undo ... --to-revision=N` | 지정 번호로 |

`kubectl scale`, `kubectl set image`로 바꾸면 파일에는 반영되지 않아서 나중에 `apply -f`하면 파일 내용으로 돌아간다. 기록을 남기려면 YAML을 고치고 apply하는 방식이 맞다.

### 왜 굳이 이 도구들을 쓰는가

| 도구 | 해결하는 문제 |
|---|---|
| WSL / 우분투 | 윈도우에서 리눅스 개발 환경 준비 |
| Git / GitHub | 코드 변경 이력 관리와 공유·협업 |
| CLI | 반복 작업 자동화, GUI 없는 원격 서버 관리, 스크립트·AI 에이전트 연동 |
| 도커 | 개발 PC와 서버의 실행 환경 차이 줄이기 |
| 컴포즈 | 여러 컨테이너(Flask, Redis, Nginx)를 파일 하나로 관리 |
| 쿠버네티스 | 복제본 수 유지, 장애 시 재생성, 여러 서버 운영 |

반드시 순서대로 다 써야 하는 것은 아니다. 혼자 만드는 간단한 실습은 파이썬 직접 실행으로도 충분하고, 작은 프로젝트에 쿠버네티스는 오히려 과할 수 있다. "무엇을 쓸까"보다 "어떤 문제가 있는가"를 먼저 생각해야 한다.

## 실습 과정

### 1. Deployment 배포

```bash
$ cd ~/devops/guestbook && mkdir -p k8s
$ kubectl apply -f k8s/deployment.yaml --dry-run=server   # 리허설
$ kubectl apply -f k8s/deployment.yaml
$ kubectl get deploy,rs,pods
```

### 2. Service 배포와 접속

```bash
$ kubectl apply -f k8s/service.yaml
$ kubectl get svc guestbook               # 80:30080/TCP
$ kubectl describe svc guestbook          # Endpoints에 Pod IP가 보여야 함
$ minikube service guestbook              # 터미널 유지, 표시된 주소로 접속
```

### 3. 스케일링과 로드밸런싱

```bash
$ kubectl scale deployment guestbook --replicas=5
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
guestbook-68685fb5-2m9vj   1/1     Running   0          6m44s
guestbook-68685fb5-hbqmq   1/1     Running   0          6m43s
guestbook-68685fb5-kf9xc   1/1     Running   0          25s
guestbook-68685fb5-n5xwn   1/1     Running   0          6m43s
guestbook-68685fb5-v6tnr   1/1     Running   0          6m44s
$ kubectl run lb-check --rm -i --restart=Never --image=busybox:1.37 -- \
    sh -c 'for i in 1 2 3 4 5 6 7 8 9 10; do wget -q -T 3 -O- http://guestbook/healthz; echo; done'
{"hostname":"guestbook-68685fb5-kf9xc","status":"ok"}

{"hostname":"guestbook-68685fb5-v6tnr","status":"ok"}

{"hostname":"guestbook-68685fb5-2m9vj","status":"ok"}

{"hostname":"guestbook-68685fb5-hbqmq","status":"ok"}

{"hostname":"guestbook-68685fb5-hbqmq","status":"ok"}

{"hostname":"guestbook-68685fb5-v6tnr","status":"ok"}
```

로드밸런서를 따로 설정하지 않았는데 서비스가 셀렉터로 찾은 Pod들에 요청을 나눠 보냈다.

### 4. 자가 치유

```bash
$ kubectl delete pod <Pod 이름 하나>
$ kubectl get pods -w
```

### 5. 롤링 업데이트 (v1 → v2)

```bash
$ docker build -t ghcr.io/omori-aubrey/guestbook:v2 .
$ docker push ghcr.io/omori-aubrey/guestbook:v2
$ kubectl set image deployment/guestbook web=ghcr.io/omori-aubrey/guestbook:v2
$ kubectl rollout status deployment/guestbook
$ kubectl rollout history deployment/guestbook
deployment.apps/guestbook
REVISION  CHANGE-CAUSE
3         v1: 롤백 완료
4         v1: 롤백 완료
5         v1: 롤백 완료
```

### 6. 롤백

```bash
$ kubectl rollout undo deployment/guestbook
$ kubectl get rs
NAME                   DESIRED   CURRENT   READY   AGE
guestbook-555ffc47d6   3         3         0       11m
guestbook-68685fb5     4         4         4       14m
guestbook-69b45f9496   0         0         0       52m
```

### 7. 정리

```bash
$ kubectl delete pod rollout-check --ignore-not-found
$ minikube stop
```

## 파일 설명

| 파일 | 설명 |
|---|---|
| guestbook/k8s/deployment.yaml | Deployment 매니페스트 (replicas 2, 이미지 v1, 컨테이너 포트 5000) |
| guestbook/k8s/service.yaml | NodePort 서비스 (80 → 5000, nodePort 30080) |
| guestbook/templates/index.html | v2 이미지용 제목 수정 |
| week10/README.md | 10주차 실습 기록 |

## 느낀 점

지난주에는 명령어로 하나씩 만들었는데, 이번 주에는 YAML 파일에 원하는 상태를 적고 `apply`만 하니 같은 결과를 언제든 다시 만들 수 있다는 점이 편했다.
로드밸런서를 따로 설정하지 않아도 Service가 레이블로 Pod를 찾아 요청을 나눠 주고, 롤링 업데이트와 롤백이 명령어 한 줄로 되는 것을 보면서 7주차에 nginx를 직접 붙였던 것과 차이를 느꼈다.
또 "왜 굳이" 수업을 통해 도구를 많이 아는 것보다 어떤 문제를 해결하려고 쓰는지 먼저 생각해야 한다는 점을 알게 되었다.
