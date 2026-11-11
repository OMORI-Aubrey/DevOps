# 4주차 - 자동화와 협업

> 교안: 03. 자동화와 협업, 04. 네트워크, Zone.Identifier

## 학습 목표
- 절대 경로와 상대 경로를 구분하고 안전하게 사용
- `grep`, `find`, `|`(파이프)로 필요한 파일과 내용 찾기
- 변수, 인자, 조건, 반복으로 반복 작업을 자동화하는 셸 스크립트 작성
- 프로그램과 프로세스를 구분하고 PID로 프로세스 확인 및 종료
- 브랜치 → PR → Conflict 해결 → Merge 협업 흐름 수행
- IP 주소, 포트, DNS의 역할을 설명하고 `ip addr`, `ping`, `curl`, `dig`, `ss`로 확인
- 내 컴퓨터에 웹 서버를 띄우고 포트 충돌을 발생시키고 해결
- WSL로 복사한 파일에 생기는 Zone.Identifier를 커밋에서 제외

## 배운 내용

### 1. 경로와 검색
- 절대 경로: `/home/jaeyun/devops/week04/backup.sh` / 상대 경로: `./week04/backup.sh`
- `find . -type f -name "*.sh"`: 파일 찾기
- `grep -n "ERROR" server.log`: 내용 찾기 (`-i` 대소문자 무시, `-c` 개수, `-v` 반전)
- 파이프 `|`: 앞 명령의 표준 출력을 뒤 명령의 표준 입력으로 연결
  - 예: `cat server.log | grep ERROR | wc -l`

### 2. 셸 스크립트 문법
- 변수: `NAME="값"` (등호 양옆 공백 금지), 사용은 `"$NAME"`
- 조건: `if [ -d "$DIR" ]; then ... fi` (`-f` 파일, `-d` 폴더, `-z` 빈 문자열, `-eq` 같음)
- 반복: `for f in *.sh; do echo "$f"; done`
- 기본값: `${1:-test}` → 인자가 없으면 `test` 사용

### 3. 프로그램 vs 프로세스
- 프로그램: 디스크에 저장된 실행 코드 / 프로세스: 실행 중인 프로그램
- `ps aux`, `jobs`, `kill <PID>`(SIGTERM, 정상 종료 요청), `kill -9 <PID>`(SIGKILL, 강제 종료)

### 4. Git 협업
- 브랜치: 실패해도 main이 안전한 작업 공간
- Pull Request: 합치기 전에 변경 내용을 검토받는 요청
- Conflict: 같은 줄을 두 브랜치가 다르게 고치면 Git이 함부로 결정하지 않고 사람에게 맡김
- Merge 옵션: `--merge`(커밋 유지), `--squash`(하나로 합침), `--rebase`(일렬로 재적용)

### 5. 네트워크
브라우저에 `https://cs.inhatc.ac.kr`을 입력하면 DNS로 IP를 찾고 → 그 IP의 443 포트로 연결 → TLS 연결 → HTTPS 요청 → HTML 응답 순서로 진행된다.

| 개념 | 의미 | 비유 |
|---|---|---|
| IP 주소 | 네트워크에서 장치를 식별하는 주소 | 건물 주소 |
| 포트 | 그 컴퓨터 안의 서비스를 구분하는 번호 (0~65535) | 건물의 호수 |
| DNS | 도메인 이름 → IP 주소 변환 | 전화번호부 |
| NAT | 공유기가 사설 IP를 공인 IP로 바꿔 인터넷과 통신 | |

| 구분 | 설명 |
|---|---|
| 공인 IP | 인터넷 전체에서 유일 |
| 사설 IP | 내부 네트워크에서만 유일 (192.168.x.x, 10.x.x.x, 172.16~31.x.x) |
| 127.0.0.1 (localhost) | 내 컴퓨터 자신 |
| 0.0.0.0 (서버 bind 시) | 모든 네트워크 인터페이스에서 연결을 받음 |

| 포트 | 용도 |
|---|---|
| 22 | SSH |
| 80 / 443 | HTTP / HTTPS |
| 3306 / 6379 | MySQL / Redis |
| 5000 / 8080 | Flask 개발 서버 / 개발용 웹 서버에서 자주 사용 |

TCP는 전달 확인과 순서를 보장하는 등기우편, UDP는 확인 없이 빠른 우편에 가깝다.

| 명령어 | 확인하는 것 |
|---|---|
| `ip addr`, `hostname -I` | 내 사설 IP |
| `curl ifconfig.me` | 내 공인 IP |
| `ping -c 4 <주소>` | 상대 장치 응답 여부 (ICMP) |
| `dig <도메인> +short`, `nslookup` | DNS 조회 |
| `curl -I <URL>` | HTTP 응답 헤더와 상태 코드 |
| `ss -tlnp` | LISTEN 중인 TCP 포트와 프로세스 |

- ping이 실패해도 서버가 죽은 것은 아니다. 방화벽에서 ICMP를 막는 경우가 많아서, `curl`로 HTTP 응답이 오는지 확인해야 한다 (400이어도 웹 서버까지 통신은 된 것).
- 서버 프로그램이 실행 중이어도 LISTEN 상태가 아니면 요청을 받을 수 없고, LISTEN 중이어도 방화벽이 포트를 막으면 외부에서 접속할 수 없다.
- 응답 코드: 200 성공, 400 잘못된 요청, 404 없음, 500 서버 에러, 503 서비스 불가 (4xx 클라이언트, 5xx 서버)
- `jq`: JSON에서 원하는 값만 뽑는 도구 (`jq -r '.name'`)

### 6. Zone.Identifier
- 윈도우가 인터넷 등 외부에서 받은 파일에 붙이는 표시(Mark of the Web)로, ADS(대체 데이터 스트림) 형태로 저장된다.
- 탐색기에서는 안 보이지만, `/mnt/c`에서 WSL로 복사하면 `index.html:Zone.Identifier` 같은 파일로 나타나 Git에 같이 올라갈 수 있다.

| 상황 | 대응 |
|---|---|
| 예방 | `.gitignore`에 `*:Zone.Identifier` 추가 |
| 이미 생김 | `find . -type f -name '*:Zone.Identifier' -delete` |
| 이미 커밋함 | 삭제 후 `git add -A` → `git commit --amend --no-edit` |

## 실습 과정

### 백업 스크립트 (backup.sh)
```bash
SOURCE_DIR=${1:-test}             # 인자 없으면 test 디렉터리
BACKUP_DIR="backups"
TODAY=$(date +%Y%m%d_%H%M%S)
FILENAME="${TODAY}_$$.tar.gz"     # $$: 현재 셸의 PID (이름 충돌 방지)
...
if [ $? -eq 0 ]; then
  SIZE=$(du -sh "$BACKUP_DIR/$FILENAME" | cut -f1)
  echo "[$(date +%H:%M:%S)] 백업 완료! (파일: $FILENAME, 크기: $SIZE)"
```
전체 코드: [backup.sh](backup.sh)

동작 순서:
1. 원본 폴더 확인 (없으면 오류 후 종료)
2. `backups/` 폴더 준비
3. `날짜_PID.tar.gz` 이름으로 압축
4. 성공 여부와 크기 출력
5. 보관 중인 백업 목록 출력

```bash
$ ./backup.sh test
백업 시작: test → backups/20261021_102208_4101.tar.gz
[10:22:08] 백업 완료! (파일: 20261021_102208_4101.tar.gz, 크기: 4.0K)
현재 보관 중인 백업:
20260928_181844_1545.tar.gz
20261021_102208_4101.tar.gz
```
- 파일명 `20261021_102208_4101` = 날짜_시각_PID → 같은 초에 실행해도 이름이 겹치지 않음

### 백업 복원 검증
```bash
ARCHIVE="backups/20260928_181844_1545.tar.gz"
tar -tzf "$ARCHIVE"                       # 압축 안의 파일 목록
mkdir -p restore-check
tar -xzf "$ARCHIVE" -C restore-check      # 복원
diff -rq test restore-check/test          # 원본과 비교
echo $?                                   # 0이면 원본과 같음
```
```
$ diff -rq test restore-check/test
$ echo $?
0
```
- diff 출력이 없고 종료 코드가 0 → 복원한 파일이 원본과 같음 (1: 다름, 2: 오류)

| tar 옵션 | 의미 |
|---|---|
| `-czf` | create, gzip, 파일명 → 압축 생성 |
| `-tzf` | list → 내용 확인 |
| `-xzf` | extract → 압축 해제 |
| `-C` | 작업할 디렉터리 지정 |

### 웹 서버 띄우기와 포트 충돌
```bash
$ mkdir -p ~/devops/week04/site && cd ~/devops/week04/site
$ cp "/mnt/c/<경로>/index.html" .
$ python3 -m http.server 8080            # 터미널 1, 브라우저에서 http://localhost:8080

$ curl -I http://localhost:8080          # 터미널 2, 200 OK 확인
$ ss -tlnp | grep 8080                   # LISTEN 확인
$ python3 -m http.server 8080            # 같은 포트로 또 실행 → Address already in use
```
포트 충돌 해결은 다른 포트를 쓰거나(`python3 -m http.server 8000`), `ss -tlnp | grep 8080`으로 PID를 찾아 `kill <PID>`로 기존 서버를 종료한다.

### Zone.Identifier 제거
```bash
$ ls ~/devops/week04/site                # index.html:Zone.Identifier 확인
$ find . -type f -name '*:Zone.Identifier' -delete
$ echo '*:Zone.Identifier' >> .gitignore
```

## 파일 설명
| 파일 | 설명 |
|---|---|
| `backup.sh` | 폴더를 날짜별 tar.gz로 백업하는 스크립트 |
| `test/` | 백업 대상 테스트 폴더 |
| `backups/` | 백업 결과물 (`.gitignore`로 Git에서 제외) |
| `restore-check/` | 복원 검증용 폴더 (`.gitignore`로 Git에서 제외) |
| `site/index.html` | `python3 -m http.server`로 띄운 웹 서버용 페이지 |

## 느낀 점
파일 백업 스크립트를 직접 작성하고 실행해 보면서 반복적인 작업을 자동화할 수 있다는 점이 유용하게 느껴졌습니다.
또 내 컴퓨터에 웹 서버를 띄우고 같은 포트로 한 번 더 실행해 포트 충돌을 직접 겪어 보면서, 앞으로 도커에서 쓸 `-p 8080:80` 같은 포트 설정이 왜 중요한지 이해할 수 있었습니다.
