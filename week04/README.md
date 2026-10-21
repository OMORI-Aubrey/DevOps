# 4주차 - 자동화와 협업

> 교안: 03. 자동화와 협업

## 학습 목표
- 절대 경로와 상대 경로를 구분하고 안전하게 사용
- `grep`, `find`, `|`(파이프)로 필요한 파일과 내용 찾기
- 변수, 인자, 조건, 반복으로 반복 작업을 자동화하는 셸 스크립트 작성
- 프로그램과 프로세스를 구분하고 PID로 프로세스 확인 및 종료
- 브랜치 → PR → Conflict 해결 → Merge 협업 흐름 수행

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


## 파일 설명
| 파일 | 설명 |
|---|---|
| `backup.sh` | 폴더를 날짜별 tar.gz로 백업하는 스크립트 |
| `test/` | 백업 대상 테스트 폴더 |
| `backups/` | 백업 결과물 (`.gitignore`로 Git에서 제외) |
| `restore-check/` | 복원 검증용 폴더 (`.gitignore`로 Git에서 제외) |

## 느낀 점
파일 백업 스크립트를 직접 작성하고 실행해 보면서 반복적인 작업을 자동화할 수 있다는 점이 유용하게 느껴졌습니다.
