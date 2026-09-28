# 4주차

## 오늘 배운 내용
- 셸 스크립트로 백업 자동화 (backup.sh)
- 백업 파일을 복원해서 원본과 같은지 확인

## 새로 배운 명령어
```bash
./backup.sh test
tar -tzf "$ARCHIVE"
tar -xzf "$ARCHIVE" -C restore-check
diff -rq test restore-check/test
echo $?
```
