# 2주차 - 실습 환경 구축과 버전 관리 기초

> 교안: 01. 실습 환경 구축과 버전 관리 기초

## 학습 목표
- WSL2와 Ubuntu로 리눅스 실습 환경 구축
- 기본 리눅스 명령어로 파일과 디렉터리 다루기
- Git으로 버전 관리, GitHub에 저장소 생성

## 배운 내용

### 1. 가상화
- **서버**: 무언가를 제공(serve)하는 주체. 하드웨어와 소프트웨어 두 의미로 모두 쓰임
- **가상화**: 물리적인 컴퓨팅 환경 안에 여러 개의 논리적인 컴퓨팅 환경을 만드는 기술

| 방식 | 설명 | 특징 |
|---|---|---|
| 베어메탈 | PC 한 대에 OS 설치 후 여러 소프트웨어 운영 | 관리는 쉽지만 한 프로그램 문제가 다른 프로그램에 영향 |
| 하이퍼바이저 | PC 한 대에 여러 가상 머신(게스트 OS) | VM마다 게스트 OS와 커널이 따로 있음 → 무거움 |
| 컨테이너 | 호스트 OS 커널을 공유하며 격리된 공간 생성 | 가볍고 빠름 (namespace: 격리, cgroups: 자원 제한) |

### 2. WSL2 (Windows Subsystem for Linux)
- 윈도우에서 리눅스를 가상 머신보다 가볍게 사용
- 설치: 파워셸(관리자)에서 `wsl --install`
- 작업 공간: `~/devops` (리눅스 홈 디렉터리 아래)

### 3. 리눅스 기본 명령어
- 디렉터리: `pwd`, `ls -l`, `ls -a`, `cd`, `mkdir`, `rmdir`
- 파일: `touch`, `echo "..." > 파일`, `cat`, `cp`, `mv`, `rm`
- 권한: `ls -l`의 `-rwxr-xr--` 읽는 법, `chmod 755` (r=4, w=2, x=1)
- 정보: `whoami`, `uname -a`, `df -h`, `free -h`, `history`

### 4. Git / GitHub
- Git: 파일의 변경 이력을 기록하고 관리하는 버전 관리 도구
- `git add`는 저장이 아니라 **다음 커밋에 포함할 변경을 고르는 것** (staging)
- `git commit`은 준비된 변경을 하나의 버전(스냅샷)으로 기록 (게임 세이브 포인트)
- 브랜치: 특정 커밋을 가리키는 이름. 서로 다른 작업을 독립적으로 진행
- GitHub: Git 저장소를 온라인에 공유하고 협업하는 공간

## 실습 과정

### Git 저장소 만들기
```bash
cd ~/devops
git init
mkdir week02 && cd week02
echo "Hello, DevOps!" > text.txt
git add text.txt
git commit -m "first commit"
git log --oneline
```

### 브랜치 실습
```bash
echo "hello" > hello.txt
git add . && git commit -m "hello"
git switch -c hello
echo "hi" > hello.txt
git add . && git commit -m "hello -> hi"
git switch main && cat hello.txt
git switch hello && cat hello.txt
git diff main hello
```
- 같은 파일이라도 브랜치마다 내용이 다르게 보임 → 브랜치는 서로 독립된 작업 공간

### GitHub 연결
```bash
gh auth login
gh repo create DevOps --public --source=. --remote=origin --push
```

## 새로 배운 명령어
```bash
!!          # 바로 직전 명령 다시 실행 (예: sudo !!)
!ls         # 가장 최근 ls로 시작한 명령 다시 실행
!103        # history 103번 명령 실행
git log --oneline --all --graph
git switch -d <커밋해시>   # 특정 커밋으로 이동
git diff <해시1> <해시2>
```

## 파일 설명
| 파일 | 설명 |
|---|---|
| `text.txt` | 첫 커밋 실습용 파일 |
| `hello.txt` | 브랜치 실습용 파일 |

## 느낀 점

지금껏 GitHub 웹사이트를 통해서만 관련 기능을 사용해왔는데,
이번에 CLI를 이용해 직접 명령어로 사용해 보니 색다른 느낌이었습니다.
웹사이트에서 사용하는 것과는 또 다른 방식으로 GitHub를 활용할 수 있다는 점이 흥미로웠고,
새로운 사용 방법을 배울 수 있어 좋았습니다.
