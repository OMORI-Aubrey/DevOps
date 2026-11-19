# 12주차 - 깃허브 액션

> 교안: 12. 깃허브 액션

## 학습 목표

- CI와 CD의 차이와 CI가 해결하려는 문제를 설명한다.
- workflow, trigger, job, step, runner의 구조를 설명한다.
- push 시 린트 → 테스트 → 빌드 → ghcr.io 푸시가 자동으로 실행되는 워크플로를 작성한다.
- 일부러 실패(빨간X)시키고 고쳐서 성공(초록✓)으로 만든다.
- 브랜치 보호 규칙으로 검사를 통과하지 못한 코드가 main에 합쳐지지 않게 한다.

## 배운 내용

### CI / CD

지금까지는 코드 수정 → `docker build` → `docker push` → `kubectl set image`를 매번 손으로 했고, 오류가 있는 코드가 main에 들어가도 알 방법이 없었다.

| | 의미 |
|---|---|
| CI (지속적 통합) | 코드를 합칠 때마다 자동으로 검사·빌드해서 문제를 일찍 발견 |
| CD - Delivery (지속적 제공) | 언제든 배포 가능한 상태 유지 (운영 반영은 승인을 거칠 수 있음) |
| CD - Deployment (지속적 배포) | 검증을 통과한 변경을 운영까지 자동 반영 |

파이프라인: 소스 가져오기 → 검사·테스트 → 이미지 빌드 → ghcr.io 푸시 (여기까지 CI) → 쿠버네티스 배포 (CD). 한 단계라도 실패하면 뒤 단계는 실행되지 않는다.

### 워크플로 구조

| 용어 | 의미 |
|---|---|
| workflow | `.github/workflows/*.yml` 파일 하나 |
| trigger (`on`) | 언제 실행할지 (push, pull_request, workflow_dispatch 등) |
| job | 깨끗한 새 서버에서 시작하는 작업 단위 (여러 개면 기본 병렬, `needs`로 순서 지정) |
| step | job 안의 한 단계. `uses`(만들어진 액션) 또는 `run`(직접 명령) |
| runner (`runs-on`) | 실제로 실행되는 서버. `ubuntu-latest`는 깃허브가 빌려줌 |

읽는 순서는 언제(`on`) → 어디서(`runs-on`) → 무엇을(`steps`).

각 step의 성공 여부는 화면 출력이 아니라 **종료 코드**로만 판단한다 (0이면 초록✓, 그 외는 빨간X).

| 표기 | 의미 |
|---|---|
| `${{ github.actor }}` | 실행을 일으킨 사람 |
| `${{ github.event_name }}` | push, pull_request 등 |
| `${{ github.ref }}` | main push면 `refs/heads/main` |
| `${{ secrets.GITHUB_TOKEN }}` | 실행마다 깃허브가 자동 발급하는 임시 토큰 (끝나면 만료) |
| `${{ steps.meta.outputs.tags }}` | `id: meta` 단계가 만든 태그 목록 |

변수 표기가 도구마다 다르다: 컴포즈 `${VAR}`, 쿠버네티스 `$(VAR)`, 액션 `${{ ... }}`.

### 문법 검사 vs 린트 vs 테스트

| | 문법 검사 (compileall) | 린트 (ruff) | 테스트 (unittest) |
|---|---|---|---|
| 묻는 것 | 파이썬이 읽을 수 있나? | 읽히는데 버그 가능성은? | 의도대로 동작하나? |
| 코드 실행 | X | X | O |
| 잡는 예 | `def broken(:` | `print(APP_TITL)` 오타 | `/healthz`가 500 |
| 속도 | 아주 빠름 | 빠름 | 조금 느림 |

워크플로에서는 싸고 빠른 검사부터 배치해서 일찍 실패하게 한다. 테스트를 통과했다고 버그가 없는 건 아니고, 테스트한 부분만 보장된다.

`ruff check . --select=E9,F` → E9: 문법 오류 / F: 정의 안 된 변수, 안 쓰는 import 등

### 테스트 코드와 워크플로

| | test_app.py | build.yml |
|---|---|---|
| 역할 | 무엇이 올바른 동작인지 (시험 문제와 정답) | 언제, 어디서, 어떤 순서로 검사할지 (자동화 지시서) |
| 언어 | 파이썬 | YAML |
| 위치 | `guestbook/tests/` | `.github/workflows/` (저장소 루트) |

테스트 파일과 함수 이름은 `test`로 시작해야 인식되고, `assertEqual(실제, 기대)`가 다르면 종료 코드 1로 실패한다. `app.test_client()`는 서버를 띄우지 않고 요청을 보내는 가상 브라우저다.

### 태그와 권한

- `latest`는 계속 덮어써져서 어제 버전이 뭔지 알 수 없다. 커밋 해시(7자리)로 태그를 붙이면 "이 이미지는 이 커밋으로 만들었다"를 추적할 수 있다.
- PR에서는 빌드까지만 하고, main에 push(머지)됐을 때만 ghcr.io에 푸시한다.
- ghcr.io는 `GITHUB_TOKEN`이 자동 제공되므로 시크릿을 따로 만들 필요가 없고, `permissions: packages: write`만 준다.

### 브랜치 보호

CI는 실패를 알려줄 뿐 머지를 막지는 않는다. Settings > Rulesets에서 "Require a pull request before merging"과 "Require status checks to pass(build)"를 켜야 검사 실패 PR의 머지 버튼이 잠기고, main에 직접 push도 거부된다. CI의 진짜 가치는 빌드보다 main을 지키는 것이다.

## 실습 과정

### 1. 테스트 코드와 워크플로 작성

```bash
$ git switch -c feature/ci-setup
$ mkdir -p guestbook/tests .github/workflows
# guestbook/tests/test_app.py, .github/workflows/build.yml 작성
$ git add .github guestbook/tests guestbook/templates
$ git commit -m "CI 파이프라인 추가"
$ git push -u origin feature/ci-setup
$ gh pr create --fill
$ gh pr checks --watch
$ gh pr merge --squash --delete-branch
```

워크플로 단계: 소스 가져오기 → Python 준비 → 코드 검사(ruff) → 앱 동작 테스트(unittest) → QEMU/Buildx 준비 → ghcr.io 로그인(main만) → 태그 결정(커밋 해시, latest) → 빌드 & 푸시

```bash
$ gh run list --limit 5
STATUS  TITLE         WORKFLOW              BRANCH             EVENT         ID           ELAPSED  AGE
✓       문법오류확인  Build and Push Image  feature/ci-errors  pull_request  44450586725  55s      about 1 hour ago
X       문법오류확인  Build and Push Image  feature/ci-errors  pull_request  44450426062  14s      about 1 hour ago
X       문법오류확인  Build and Push Image  feature/ci-errors  pull_request  44450237466  13s      about 1 hour ago
✓       문법오류확인  Build and Push Image  feature/ci-errors  pull_request  44449907546  1m19s    about 1 hour ago
X       문법오류확인  Build and Push Image  feature/ci-errors  pull_request  44449772485  11s      about 1 hour ago
```

`docker build`나 `docker push`를 직접 하지 않았는데, 머지만으로 Packages에 커밋 해시 태그 이미지가 올라왔다. 이 이미지를 `kubectl set image deployment/guestbook web=ghcr.io/omori-aubrey/guestbook:<커밋태그>`로 쿠버네티스에 반영했다 (자동화는 다음 주 CD).

### 2. 빨간X → 초록✓

| 실험 | 넣은 오류 | 실패한 단계 |
|---|---|---|
| 문법 오류 | `def broken(:` | 코드 검사 |
| 오타 | `print(APP_TITL)` (compileall은 통과) | 코드 검사 (F821) |
| 동작 오류 | `/healthz`가 500 반환 | 앱 동작 테스트 (`500 != 200`) |

```bash
$ gh run view --log-failed
```

로그는 맨 아래(`exit code 1`)부터 위로 올라가며 첫 오류 줄, 파일명과 줄 번호를 찾는다. 고친 뒤 push하면 PR 검사가 다시 돌아 초록✓가 된다.

### 3. main 브랜치 보호

```bash
$ git commit -m "test" && git push       # main에 직접 push
(출력 - push declined due to repository rule violations)
$ git reset --hard origin/main
```

깨진 코드로 PR을 올리면 머지 버튼이 비활성화되고, 고쳐서 초록✓가 되면 활성화된다. 이후 주차 README도 브랜치 → PR → 머지로 올린다.

## 파일 설명

| 파일 | 설명 |
|---|---|
| .github/workflows/build.yml | 린트 → 테스트 → 빌드 → ghcr.io 푸시 워크플로 |
| guestbook/tests/test_app.py | /healthz 응답, 글 등록·조회 테스트 |
| guestbook/templates/index.html | 변경 확인용 제목 문구 수정 (v2 → new) |
| week12/README.md | 12주차 실습 기록 |

## 느낀 점

github가 알아서 프로젝트를 검사해주니 main에 오류가 생길 가능성이 훨씬 낮아져 정말 유용한 기능이라고 생각합니다.

